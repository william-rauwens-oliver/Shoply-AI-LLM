#!/usr/bin/env julia

using Pkg
Pkg.activate(@__DIR__)
for pkg in ["Transformers", "ProgressMeter"]
    isnothing(Base.find_package(pkg)) && Pkg.add(pkg)
end

using Transformers
using Transformers.Basic: generate
using Transformers.HuggingFace: hgf, load_hgf_model!

function parse_args()
    prompt = ""
    model_id = "gpt2"
    max_tokens = 60
    mode = "single"  # single ou chat
    temperature = 0.8
    top_k = 50
    top_p = 0.95

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
        elseif arg == "--help" || arg == "-h"
            println("""Utilisation:
  julia llm_demo.jl [options]

Options:
  --prompt=TEXT          Texte initial
  --model=ID             Modèle (défaut: gpt2)
  --max-tokens=N         Max tokens générés (défaut: 60)
  --temperature=T        Créativité 0.1-2.0 (défaut: 0.8)
  --mode=single|chat     Mode (défaut: single)
  --help                 Affiche cette aide
            """)
            exit(0)
        end
        i += 1
    end

    return (; prompt, model_id, max_tokens, mode, temperature, top_k, top_p)
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
    """Mode conversation multi-tour."""
    history = String[]
    token_count = 0
    start_time = time()

    println("\n💬 Mode conversation (quit=quitter, clear=réinitialiser)\n")

    while true
        print("👤 Vous: ")
        user_input = readline()
        
        if user_input == "quit"
            break
        elseif user_input == "clear"
            empty!(history)
            token_count = 0
            println("🗑️  Historique effacé.\n")
            continue
        elseif isempty(strip(user_input))
            continue
        end

        # Contexte avec historique (limité)
        context = ""
        if length(history) > 0
            context = join(history[end-min(2, length(history)-1):end], " ")
        end
        prompt = isempty(context) ? user_input : "$context $user_input"

        result, elapsed = generate_text(model, tokenizer, prompt, args)

        if !isnothing(result)
            # Extrait réponse nouvelle
            response = if length(result) > length(prompt)
                strip(result[length(prompt)+1:end])
            else
                result
            end
            println("🤖 IA: $response\n")
            push!(history, user_input)
            push!(history, response)
            token_count += args.max_tokens
        else
            println("⚠️  Erreur de génération.\n")
        end
    end

    # Stats
    total_time = time() - start_time
    n_exchanges = div(length(history), 2)
    println("\n📊 Stats: $n_exchanges échanges, ~$token_count tokens, $(round(total_time, digits=1))s total")
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
