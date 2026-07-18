"use client";

import { useState, useRef, useEffect, useCallback } from "react";
import { Send } from "lucide-react";
import { converse } from "@/lib/api";
import type { ConversationTurn } from "@/lib/types";
import SkeletonLoader from "./SkeletonLoader";

interface ChatPanelProps {
  caseId: string;
  onMessagesChange?: (messages: ConversationTurn[]) => void;
}

export default function ChatPanel({ caseId, onMessagesChange }: ChatPanelProps) {
  const [messages, setMessages] = useState<ConversationTurn[]>([]);

  // Notify parent of message changes (for PDF export)
  useEffect(() => {
    onMessagesChange?.(messages);
  }, [messages, onMessagesChange]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages, isLoading, scrollToBottom]);

  const handleSend = async () => {
    const question = input.trim();
    if (!question || isLoading) return;

    setInput("");
    setError(null);

    // Add officer message immediately
    const officerTurn: ConversationTurn = {
      role: "officer",
      content: question,
    };
    const updatedMessages = [...messages, officerTurn];
    setMessages(updatedMessages);
    setIsLoading(true);

    try {
      const answer = await converse(caseId, question, messages);
      const gemmaTurn: ConversationTurn = {
        role: "gemma",
        content: answer,
      };
      setMessages((prev) => [...prev, gemmaTurn]);
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Failed to get response from Gemma",
      );
    } finally {
      setIsLoading(false);
      inputRef.current?.focus();
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="chat-panel">
      <div className="chat-panel-header">
        <div className="chat-panel-header-dot" />
        <h3>Audit Agent — Live Conversation</h3>
        <span className="chat-panel-header-hint">
          Ask any question about this case. Gemma reasons over the extracted
          data and signals.
        </span>
      </div>

      {/* Messages area */}
      <div className="chat-messages">
        {messages.length === 0 && !isLoading && (
          <div className="chat-empty">
            <p className="chat-empty-title">No conversation yet</p>
            <p className="chat-empty-hint">
              Ask a question to start the audit conversation. Examples:
            </p>
            <div className="chat-suggestions">
              {[
                "Why was this case flagged?",
                "Explain the Benford's Law analysis",
                "Are there entity mismatches across documents?",
                "What is the transaction velocity concern?",
              ].map((suggestion) => (
                <button
                  key={suggestion}
                  className="chat-suggestion-chip"
                  onClick={() => {
                    setInput(suggestion);
                    inputRef.current?.focus();
                  }}
                >
                  {suggestion}
                </button>
              ))}
            </div>
          </div>
        )}

        {messages.map((msg, i) => (
          <div
            key={i}
            className={`chat-message chat-message-${msg.role}`}
          >
            <div className="chat-message-avatar">
              {msg.role === "officer" ? "👤" : "🤖"}
            </div>
            <div className="chat-message-content">
              <span className="chat-message-role">
                {msg.role === "officer" ? "You" : "Gemma"}
              </span>
              <p>{msg.content}</p>
            </div>
          </div>
        ))}

        {/* Loading state — skeleton pulse bubble */}
        {isLoading && (
          <div className="chat-message chat-message-gemma">
            <div className="chat-message-avatar">🤖</div>
            <div className="chat-message-content">
              <span className="chat-message-role">Gemma</span>
              <div className="chat-thinking">
                <SkeletonLoader variant="chat-bubble" />
                <span className="chat-thinking-label">
                  Reasoning over case data…
                </span>
              </div>
            </div>
          </div>
        )}

        {/* Error state */}
        {error && (
          <div className="chat-error">
            <p>{error}</p>
            <button
              onClick={() => setError(null)}
              className="chat-error-dismiss"
            >
              Dismiss
            </button>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input area */}
      <div className="chat-input-area">
        <textarea
          ref={inputRef}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Ask a question about this case…"
          className="chat-input"
          rows={1}
          disabled={isLoading}
        />
        <button
          onClick={handleSend}
          disabled={!input.trim() || isLoading}
          className="chat-send-btn"
          title="Send"
        >
          <Send size={18} />
        </button>
      </div>
    </div>
  );
}
