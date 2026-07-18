"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Shield, ChevronRight, LogOut } from "lucide-react";
import { useAuth } from "@/context/AuthContext";

export default function Navbar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();

  // Build breadcrumbs from the pathname
  const crumbs: { label: string; href: string }[] = [
    { label: "Cases", href: "/" },
  ];

  if (pathname.startsWith("/case/")) {
    const caseId = pathname.split("/case/")[1];
    crumbs.push({
      label: `Case ${caseId?.slice(0, 8)}…`,
      href: pathname,
    });
  }

  // Don't render the main navbar elements on the login screen
  if (pathname === "/login") {
    return (
      <nav className="navbar border-b border-[var(--color-border)] h-14 bg-[var(--color-bg-surface)] px-6 flex items-center justify-between z-50 fixed top-0 w-full">
         <div className="navbar-brand">
          <Shield size={20} strokeWidth={2.5} className="text-[var(--color-accent)]" />
          <span className="navbar-brand-text font-bold">
            Audit<span className="text-[var(--color-accent)]">Gemma</span>
          </span>
        </div>
      </nav>
    );
  }

  return (
    <nav className="navbar h-14 border-b border-[var(--color-border)] bg-[var(--color-bg-surface)] px-6 flex items-center justify-between z-50 fixed top-0 w-full text-sm">
      <div className="navbar-inner flex items-center gap-8 h-full w-full justify-between">
        <div className="flex items-center gap-6">
          {/* Logo */}
          <Link href="/" className="navbar-brand flex items-center gap-2 text-[var(--color-text-primary)] hover:opacity-80 transition-opacity">
            <Shield size={20} strokeWidth={2.5} className="text-[var(--color-accent)]" />
            <span className="navbar-brand-text font-bold tracking-tight">
              Audit<span className="text-[var(--color-accent)]">Gemma</span>
            </span>
          </Link>

          {/* Breadcrumbs */}
          <div className="navbar-breadcrumbs flex items-center gap-2 text-[var(--color-text-muted)] font-mono text-xs">
            {crumbs.map((crumb, i) => (
              <span key={crumb.href} className="navbar-crumb-item flex items-center gap-2">
                {i > 0 && (
                  <ChevronRight size={14} className="navbar-crumb-sep opacity-50" />
                )}
                {i === crumbs.length - 1 ? (
                  <span className="navbar-crumb-current text-[var(--color-text-primary)] font-semibold">{crumb.label}</span>
                ) : (
                  <Link href={crumb.href} className="navbar-crumb-link hover:text-[var(--color-text-primary)] transition-colors">
                    {crumb.label}
                  </Link>
                )}
              </span>
            ))}
          </div>
        </div>

        {/* Right side — user controls */}
        <div className="navbar-right flex items-center gap-4">
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-[var(--color-bg-inset)] border border-[var(--color-border)]">
            <div className="navbar-status-dot w-2 h-2 rounded-full bg-[var(--color-success)]" />
            <span className="navbar-user text-xs font-semibold text-[var(--color-text-secondary)]">
              {user?.email?.split('@')[0] || "Officer"}
            </span>
          </div>
          
          <button 
            onClick={() => logout()}
            className="flex items-center justify-center p-2 rounded-lg text-[var(--color-text-muted)] hover:text-[var(--color-danger)] hover:bg-[var(--color-danger)]/10 transition-colors"
            title="Log Out"
          >
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </nav>
  );
}
