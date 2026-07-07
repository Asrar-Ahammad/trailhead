import { SignIn } from "@clerk/nextjs";
import { clerkAppearance } from "@/lib/clerkAppearance";

export default function Page() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4 py-12 select-none">
      <div className="w-full max-w-md flex flex-col items-center justify-center gap-6">
        {/* Simple Brand Header */}
        <div className="flex flex-col items-center gap-1.5 text-center">
          <span className="text-2xl font-black uppercase tracking-wider text-primary">Trailhead</span>
          <span className="text-xs text-muted-foreground">Track your runs offline, sync seamlessly.</span>
        </div>

        <SignIn appearance={clerkAppearance} />
      </div>
    </div>
  );
}
