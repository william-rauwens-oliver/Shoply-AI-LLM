import React, { useState, useRef, useEffect } from "react";
import axios from "axios";
import "./App.css";

const API_BASE_URL = "http://127.0.0.1:7860";

export default function App() {
  const [messages, setMessages] = useState([
    {
      role: "system",
      content: "LLM Chat initialized. Ready for conversation.",
    },
  ]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [model, setModel] = useState("sshleifer/tiny-gpt2");
  const [systemPrompt, setSystemPrompt] = useState(
    "You are a helpful AI assistant."
  );
  const [temperature, setTemperature] = useState(0.8);
  const [serverStatus, setServerStatus] = useState("offline");
  const messagesEndRef = useRef(null);

  useEffect(() => {
    checkServerStatus();
    const interval = setInterval(checkServerStatus, 5000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const checkServerStatus = async () => {
    try {
      await axios.get(`${API_BASE_URL}/health`, { timeout: 2000 });
      setServerStatus("online");
    } catch {
      setServerStatus("offline");
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  const sendMessage = async () => {
    if (!input.trim() || loading) return;

    const userMessage = input.trim();
    setInput("");
    setMessages((prev) => [...prev, { role: "user", content: userMessage }]);
    setLoading(true);

    try {
      const response = await axios.post(`${API_BASE_URL}/api/chat`, {
        message: userMessage,
        system: systemPrompt,
        temperature,
        model,
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
          content:
            "Error: Unable to reach LLM server. Ensure backend is running on port 7860.",
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="sidebar-header">
          <h2>Configuration</h2>
          <div className={`status-indicator ${serverStatus}`}></div>
        </div>

        <div className="settings-group">
          <label>Model</label>
          <select value={model} onChange={(e) => setModel(e.target.value)}>
            <option value="sshleifer/tiny-gpt2">tiny-gpt2 (Lightweight)</option>
            <option value="distilgpt2">distilgpt2 (Standard)</option>
            <option value="gpt2">gpt2 (Full)</option>
          </select>
        </div>

        <div className="settings-group">
          <label>
            Temperature: <span>{temperature.toFixed(2)}</span>
          </label>
          <input
            type="range"
            min="0.1"
            max="2"
            step="0.1"
            value={temperature}
            onChange={(e) => setTemperature(parseFloat(e.target.value))}
          />
        </div>

        <div className="settings-group">
          <label>System Prompt</label>
          <textarea
            value={systemPrompt}
            onChange={(e) => setSystemPrompt(e.target.value)}
            placeholder="Define AI behavior..."
          />
        </div>

        <button className="btn-clear" onClick={() => setMessages([])}>
          Clear History
        </button>

        <div className="server-info">
          <small>Server: {serverStatus}</small>
          <small>Temperature: {temperature.toFixed(2)}</small>
        </div>
      </aside>

      <main className="chat-container">
        <header className="chat-header">
          <h1>LLM Chat</h1>
          <small>Apple Silicon Optimized</small>
        </header>

        <div className="messages-area">
          {messages.map((msg, idx) => (
            <div key={idx} className={`message message-${msg.role}`}>
              <div className="message-label">
                {msg.role === "user" && "You"}
                {msg.role === "assistant" && "Assistant"}
                {msg.role === "system" && "System"}
                {msg.role === "error" && "Error"}
              </div>
              <div className="message-content">{msg.content}</div>
            </div>
          ))}
          {loading && (
            <div className="message message-loading">
              <div className="typing-dots">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <footer className="input-area">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === "Enter" && sendMessage()}
            placeholder="Type a message..."
            disabled={loading || serverStatus === "offline"}
          />
          <button
            onClick={sendMessage}
            disabled={loading || serverStatus === "offline" || !input.trim()}
          >
            Send
          </button>
        </footer>
      </main>
    </div>
  );
}
