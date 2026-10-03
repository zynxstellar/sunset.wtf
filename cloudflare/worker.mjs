const SOURCE_URL =
  "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/refs/heads/main/alua";

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (request.method !== "GET" || url.pathname !== "/alua") {
      return new Response("Not found", { status: 404 });
    }

    try {
      const source = await fetch(SOURCE_URL, { cache: "no-store" });
      if (!source.ok) {
        return new Response("Sunset source is unavailable", { status: 502 });
      }

      return new Response(source.body, {
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "no-store",
        },
      });
    } catch {
      return new Response("Sunset source is unavailable", { status: 502 });
    }
  },
};
