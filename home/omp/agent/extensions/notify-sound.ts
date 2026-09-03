import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { spawn } from "child_process";

export default function (pi: ExtensionAPI) {
  pi.on("agent_end", async () => {
    try {
      const child = spawn("/home/gbshadow/.local/bin/omp-notify-sound.sh", [], {
        detached: true,
        stdio: "ignore",
      });
      child.unref();
    } catch {
      // Best-effort
    }
  });
}
