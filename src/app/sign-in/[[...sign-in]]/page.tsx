import { SignIn } from "@clerk/nextjs";

export default function Page() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4 py-12 select-none">
      <div className="w-full max-w-md flex flex-col items-center justify-center gap-6">
        {/* Simple Brand Header */}
        <div className="flex flex-col items-center gap-1.5 text-center">
          <span className="text-2xl font-black uppercase tracking-wider text-primary">Trailhead</span>
          <span className="text-xs text-muted-foreground">Track your runs offline, sync seamlessly.</span>
        </div>

        <SignIn 
          appearance={{
            elements: {
              card: "shadow-2xl border border-border bg-card text-foreground",
              headerTitle: "text-foreground",
              headerSubtitle: "text-muted-foreground",
              socialButtonsBlockButton: "bg-secondary hover:bg-muted text-foreground border-border",
              formButtonPrimary: "bg-primary hover:bg-primary/95 text-white",
              footerActionLink: "text-primary hover:text-primary/90",
              formFieldLabel: "text-foreground",
              formFieldInput: "bg-secondary/45 border-border text-foreground focus:border-primary focus:ring-primary",
              dividerLine: "bg-border/60",
              dividerText: "text-muted-foreground",
              identityPreviewText: "text-foreground",
              identityPreviewEditButton: "text-primary",
            }
          }}
        />
      </div>
    </div>
  );
}
