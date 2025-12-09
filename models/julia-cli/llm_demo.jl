#!/usr/bin/env julia

using Pkg
Pkg.activate(@__DIR__)
for pkg in ["Transformers", "JSON"]
    isnothing(Base.find_package(pkg)) && Pkg.add(pkg)
end

using Transformers
using Transformers.Basic: generate
using Transformers.HuggingFace: hgf, load_hgf_model!
using JSON

function parse_args()
    prompt = ""
    model_id = "gpt2"
    max_tokens = 60
    mode = "single"
    temperature = 0.8
    top_k = 50
    top_p = 0.95
    system = ""
    save_history = ""
    load_history = ""
    enable_memory = false

    i = 1
    while i ≤ length(Base.ARGS)
        arg = Base.ARGS[i]
        if startswith(arg, "--prompt=")
            prompt = split(arg, "=", limit=2)[2]
        elseif startswith(arg, "--model=")
            model_id = split(arg, "=", limit=2)[2]
        elseif startswith(arg, "--max-tokens=")
            max_tokens = parse(Int, split(arg, "=", limit=2)[2])
        elseif startswith(arg, "--temperature=")
            temperature = parse(Float64, split(arg, "=", limit=2)[2])
        elseif startswith(arg, "--mode=")
            mode = split(arg, "=", limit=2)[2]
        elseif startswith(arg, "--system=")
            system = split(arg, "=", limit=2)[2]
        elseif startswith(arg, "--save-history=")
            save_history = split(arg, "=", limit=2)[2]
        elseif startswith(arg, "--load-history=")
            load_history = split(arg, "=", limit=2)[2]
        elseif arg == "--enable-memory"
            enable_memory = true
        elseif arg == "--help" || arg == "-h"
            println("""Utilisation:
  julia llm_demo.jl [options]

Options:
  --prompt=TEXT          Texte initial
  --model=ID             Modèle (défaut: gpt2)
  --max-tokens=N         Max tokens générés (défaut: 60)
  --temperature=T        Créativité 0.1-2.0 (défaut: 0.8)
  --mode=single|chat     Mode (défaut: single)
  --system=TEXT          Instructions système
  --save-history=FILE    Sauvegarder historique JSON
  --load-history=FILE    Charger historique JSON
  --enable-memory        Activer mémoire long-terme
  --help                 Affiche cette aide
            """)
            exit(0)
        end
        i += 1
    end

    return (; prompt, model_id, max_tokens, mode, temperature, top_k, top_p, system, save_history, load_history, enable_memory)
end

function generate_text(model, tokenizer, text::String, args)
    """Génère du texte avec timing."""
    try
        start_time = time()
        generated = generate(
            model,
            tokenizer,
            text;
            max_new_tokens=args.max_tokens,
            temperature=args.temperature,
            top_k=args.top_k,
            top_p=args.top_p,
            do_sample=true,
        )
        elapsed = time() - start_time
        return generated, elapsed
    catch e
        println("❌ Erreur: $e")
        return nothing, 0
    end
end

function single_mode(args, model, tokenizer)
    """Mode avec un seul prompt."""
    prompt = isempty(args.prompt) ? "Bonjour, je suis une IA intelligente" : args.prompt
    
    println("✨ Génération en cours...\n")
    result, elapsed = generate_text(model, tokenizer, prompt, args)

    if !isnothing(result)
        println("📝 Prompt:")
        println(prompt)
        println("\n🤖 Réponse:")
        println(result)
        println("\n⏱️  Temps: $(round(elapsed, digits=2))s | Tokens: $(args.max_tokens) | Temp: $(args.temperature)")
    end
end

function chat_mode(args, model, tokenizer)
    """Mode conversation multi-tour avec mémoire."""
    history = String[]
    memory = Dict("topics" => String[], "entities" => String[])
    token_count = 0
    start_time = time()

    # Charger historique si demandé
    if !isempty(args.load_history) && isfile(args.load_history)
        try
            data = JSON.parsefile(args.load_history)
            history = get(data, "history", String[])
            memory = get(data, "memory", memory)
            println("📂 Historique chargé ($(length(history)) messages)\n")
        catch e
            println("⚠️  Impossible de charger: $e\n")
        end
    end

    println("\n💬 Mode conversation (quit=quitter, clear=réinitialiser, mem=mémoire)\n")

    while true
        print("👤 Vous: ")
        user_input = readline()
        
        if user_input == "quit"
            break
        elseif user_input == "clear"
            empty!(history)
            memory = Dict("topics" => String[], "entities" => String[])
            token_count = 0
            println("🗑️  Historique et mémoire effacés.\n")
            continue
        elseif user_input == "mem"
            topics = length(memory["topics"]) > 3 ? memory["topics"][end-2:end] : memory["topics"]
            println("\n💾 Mémoire: Thèmes=$topics\n")
            continue
        elseif isempty(strip(user_input))
            continue
        end

        # Construit contexte
        context_msgs = ""
        if length(history) > 0
            context_msgs = join(history[end-min(2, length(history)-1):end], " ")
        end
        
        system_prompt = isempty(args.system) ? "Tu es un assistant IA utile." : args.system
        if !isempty(context_msgs) && length(context_msgs) < 200
            system_prompt *= "\n\nContexte: $context_msgs"
        end
        
        prompt = "$system_prompt\n\n👤 Vous: $user_input\n🤖 IA:"

        result, elapsed = generate_text(model, tokenizer, prompt, args)

        if !isnothing(result)
            # Extrait réponse
            response = if occursin("🤖 IA:", result)
                split(result, "🤖 IA:")[end]
            else
                result
            end
            response = strip(response)[1:min(200, length(strip(response)))]
            
            println("🤖 IA: $response\n")
            push!(history, user_input)
            push!(history, response)
            
            # Mémoire
            if args.enable_memory
                words = split(lowercase("$user_input $response"))
                for w in words[findall(x -> length(x) > 3, words)]
                    push!(memory["topics"], w)
                end
                memory["topics"] = unique(memory["topics"])[end-9:end]
            end
            
            token_count += args.max_tokens
        else
            println("⚠️  Erreur de génération.\n")
        end
    end

    # Sauvegarder
    if !isempty(args.save_history)
        try
            open(args.save_history, "w") do f
                write(f, JSON.json(Dict("history" => history, "memory" => memory)))
            end
            println("\n💾 Historique sauvegardé dans $(args.save_history)")
        catch e
            println("\n⚠️  Impossible de sauvegarder: $e")
        end
    end

    # Stats
    total_time = time() - start_time
    n_exchanges = div(length(history), 2)
    println("\n📊 Stats: $n_exchanges échanges, ~$token_count tokens, $(round(total_time, digits=1))s total")
    println("🧠 Mémoire: $(length(memory["topics"])) thèmes conservés")
end

function main()
    args = parse_args()
    
    println("📦 Chargement modèle '$(args.model_id)'...")
    tokenizer = AutoTokenizer(args.model_id)
    config = AutoConfig(args.model_id)
    model = GPT2LMHeadModel(config)
    load_hgf_model!(model, hgf"$(args.model_id)")
    
    if args.mode == "chat"
        chat_mode(args, model, tokenizer)
    else
        single_mode(args, model, tokenizer)
    end
end

main()
