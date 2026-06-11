import type { NextConfig } from "next";

const codespacesOrigin = "*." + "app" + ".github" + ".dev";

const nextConfig: NextConfig = {
  allowedDevOrigins: [codespacesOrigin],
  experimental: {
    serverActions: {
      allowedOrigins: [codespacesOrigin],
    },
  },
};

export default nextConfig;
