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
            println("""Usage:
  julia llm_demo.jl [options]

Options:
  --prompt=TEXT          Initial text
  --model=ID             Model (default: gpt2)
  --max-tokens=N         Max tokens to generate (default: 60)
  --temperature=T        Temperature 0.1-2.0 (default: 0.8)
  --mode=single|chat     Mode (default: single)
  --system=TEXT          System instructions
  --save-history=FILE    Save chat history to JSON
  --load-history=FILE    Load chat history from JSON
  --enable-memory        Enable long-term memory
  --help                 Show this help
            """)
            exit(0)
        end
        i += 1
    end

    return (; prompt, model_id, max_tokens, mode, temperature, top_k, top_p, system, save_history, load_history, enable_memory)
end

function generate_text(model, tokenizer, text::String, args)
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
        println("Error: $e")
        return nothing, 0
    end
end

function single_mode(args, model, tokenizer)
    prompt = isempty(args.prompt) ? "Hello, I am an AI assistant" : args.prompt
    
    println("Generating response...\n")
    result, elapsed = generate_text(model, tokenizer, prompt, args)

    if !isnothing(result)
        println("Prompt:")
        println(prompt)
        println("\nResponse:")
        println(result)
        println("\nTime: $(round(elapsed, digits=2))s | Tokens: $(args.max_tokens) | Temp: $(args.temperature)")
    end
end

function chat_mode(args, model, tokenizer)
    history = String[]
    memory = Dict("topics" => String[], "entities" => String[])
    token_count = 0
    start_time = time()

    if !isempty(args.load_history) && isfile(args.load_history)
        try
            data = JSON.parsefile(args.load_history)
            history = get(data, "history", String[])
            memory = get(data, "memory", memory)
            println("History loaded ($(length(history)) messages)\n")
        catch e
            println("Failed to load history: $e\n")
        end
    end

    println("Chat mode (quit=exit, clear=reset, mem=show memory)\n")

    while true
        print("You: ")
        user_input = readline()
        
        if user_input == "quit"
            break
        elseif user_input == "clear"
            empty!(history)
            memory = Dict("topics" => String[], "entities" => String[])
            token_count = 0
            println("History and memory cleared.\n")
            continue
        elseif user_input == "mem"
            topics = length(memory["topics"]) > 3 ? memory["topics"][end-2:end] : memory["topics"]
            println("\nMemory: Topics=$topics\n")
            continue
        elseif isempty(strip(user_input))
            continue
        end

        context_msgs = ""
        if length(history) > 0
            context_msgs = join(history[end-min(2, length(history)-1):end], " ")
        end
        
        system_prompt = isempty(args.system) ? "You are a helpful AI assistant." : args.system
        if !isempty(context_msgs) && length(context_msgs) < 200
            system_prompt *= "\n\nContext: $context_msgs"
        end
        
        prompt = "$system_prompt\n\nConversation:\nYou: $user_input\nAssistant:"

        result, elapsed = generate_text(model, tokenizer, prompt, args)

        if !isnothing(result)
            response = if occursin("Assistant:", result)
                split(result, "Assistant:")[end]
            else
                result
            end
            response = strip(response)[1:min(200, length(strip(response)))]
            
            println("Assistant: $response\n")
            push!(history, user_input)
            push!(history, response)
            
            if args.enable_memory
                words = split(lowercase("$user_input $response"))
                for w in words[findall(x -> length(x) > 3, words)]
                    push!(memory["topics"], w)
                end
                memory["topics"] = unique(memory["topics"])[end-9:end]
            end
            
            token_count += args.max_tokens
        else
            println("Error generating response.\n")
        end
    end

    if !isempty(args.save_history)
        try
            open(args.save_history, "w") do f
                write(f, JSON.json(Dict("history" => history, "memory" => memory)))
            end
            println("\nHistory saved to $(args.save_history)")
        catch e
            println("\nFailed to save history: $e")
        end
    end

    total_time = time() - start_time
    n_exchanges = div(length(history), 2)
    println("\nStats: $n_exchanges exchanges, ~$token_count tokens, $(round(total_time, digits=1))s total")
    println("Memory: $(length(memory["topics"])) topics retained")
end

function main()
    args = parse_args()
    
    println("Loading model '$(args.model_id)'...")
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
