import React, { useState, useRef, useEffect } from "react";
import axios from "axios";
import "./App.css";

export default function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [model, setModel] = useState("sshleifer/tiny-gpt2");
  const [systemPrompt, setSystemPrompt] = useState("Tu es un assistant IA utile.");
  const [temperature, setTemperature] = useState(0.8);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = async () => {
    if (!input.trim()) return;

    const userMessage = input.trim();
    setInput("");
    setMessages((prev) => [...prev, { role: "user", content: userMessage }]);
    setLoading(true);

    try {
      const response = await axios.post("http://localhost:7860/api/chat", {
        message: userMessage,
        system: systemPrompt,
        temperature: temperature,
        model: model,
      });

      setMessages((prev) => [
        ...prev,
        { role: "assistant", content: response.data.response },
      ]);
    } catch (error) {
      setMessages((prev) => [
        ...prev,
        {
          role: "error",
          content: "Erreur: Le serveur LLM n'est pas accessible. Assurez-vous qu'il est lancé.",
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app">
      <div className="sidebar">
        <h2>⚙️ Paramètres</h2>
        
        <div className="param-group">
          <label>🤖 Modèle</label>
          <select value={model} onChange={(e) => setModel(e.target.value)}>
            <option value="sshleifer/tiny-gpt2">tiny-gpt2 (Très léger)</option>
            <option value="distilgpt2">distilgpt2 (Léger)</option>
            <option value="gpt2">gpt2 (Standard)</option>
          </select>
        </div>

        <div className="param-group">
          <label>🎯 Température: {temperature.toFixed(2)}</label>
          <input
            type="range"
            min="0.1"
            max="2"
            step="0.1"
            value={temperature}
            onChange={(e) => setTemperature(parseFloat(e.target.value))}
          />
        </div>

        <div className="param-group">
          <label>💬 Instructions système</label>
          <textarea
            value={systemPrompt}
            onChange={(e) => setSystemPrompt(e.target.value)}
            placeholder="Décrivez le comportement de l'IA..."
          />
        </div>

        <button onClick={() => setMessages([])}>🗑️ Effacer conversation</button>
      </div>

      <div className="chat-container">
        <div className="chat-header">
          <h1>🤖 LLM AI Chat</h1>
          <p className="status">
            {loading ? "⏳ Génération..." : "✅ Prêt"}
          </p>
        </div>

        <div className="messages">
          {messages.length === 0 ? (
            <div className="empty-state">
              <h2>Bienvenue dans LLM AI Chat 👋</h2>
              <p>Optimisé pour Apple Silicon M3 Pro</p>
              <p>Tapez votre message ci-dessous pour commencer</p>
            </div>
          ) : (
            messages.map((msg, idx) => (
              <div
                key={idx}
                className={`message ${
                  msg.role === "user"
                    ? "user"
                    : msg.role === "error"
                    ? "error"
                    : "assistant"
                }`}
              >
                <div className="message-avatar">
                  {msg.role === "user" ? "👤" : msg.role === "error" ? "❌" : "🤖"}
                </div>
                <div className="message-content">{msg.content}</div>
              </div>
            ))
          )}
          {loading && (
            <div className="message assistant">
              <div className="message-avatar">🤖</div>
              <div className="message-content">
                <div className="typing-indicator">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <div className="input-area">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === "Enter" && sendMessage()}
            placeholder="Tapez votre message..."
            disabled={loading}
          />
          <button onClick={sendMessage} disabled={loading}>
            {loading ? "⏳" : "📤"} Envoyer
          </button>
        </div>
      </div>
    </div>
  );
}
