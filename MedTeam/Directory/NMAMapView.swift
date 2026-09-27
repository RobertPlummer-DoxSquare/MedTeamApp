import SwiftUI
import WebKit

struct NMAMapView: UIViewRepresentable {
    let highlightedRegion: NMARegion

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = false
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        let bg = UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)
        webView.backgroundColor = bg
        webView.scrollView.backgroundColor = bg
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(buildHTML(region: highlightedRegion), baseURL: nil)
    }

    private func buildHTML(region: NMARegion) -> String {
        let stateNamesJS = region.fullStateNames
            .map { "\"\($0)\"" }
            .joined(separator: ",")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
        <style>
          * { margin:0; padding:0; box-sizing:border-box; }
          html, body { background:#1C1C1E; width:100%; height:100%; overflow:hidden; }
          #map svg { display:block; width:100%; height:auto; }
          #loading { position:absolute; top:50%; left:50%; transform:translate(-50%,-50%);
                     color:#48484A; font-family:-apple-system,sans-serif; font-size:12px; }
        </style>
        </head>
        <body>
        <div id="map"></div>
        <div id="loading">Loading…</div>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/d3/7.8.5/d3.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/topojson/3.0.2/topojson.min.js"></script>
        <script>
        const ACTIVE = new Set([\(stateNamesJS)]);
        const W = 960, H = 560;

        const svg = d3.select("#map").append("svg")
          .attr("viewBox", "0 0 " + W + " " + H)
          .attr("width", "100%");

        svg.append("rect").attr("width", W).attr("height", H).attr("fill", "#1C1C1E");

        const projection = d3.geoAlbersUsa()
          .scale(1200).translate([W / 2 + 30, H / 2 + 20]);
        const path = d3.geoPath(projection);

        d3.json("https://cdn.jsdelivr.net/npm/us-atlas@3/states-10m.json")
          .then(us => {
            document.getElementById("loading").remove();

            svg.selectAll("path.state")
              .data(topojson.feature(us, us.objects.states).features)
              .join("path")
              .attr("class", "state")
              .attr("d", path)
              .attr("fill", d => ACTIVE.has(d.properties.name) ? "#2A7DD4" : "#2C2C2E")
              .attr("stroke", "#1C1C1E")
              .attr("stroke-width", "1.2")
              .attr("stroke-linejoin", "round");

            svg.append("path")
              .datum(topojson.mesh(us, us.objects.states, (a, b) => a !== b))
              .attr("d", path)
              .attr("fill", "none")
              .attr("stroke", "#1C1C1E")
              .attr("stroke-width", "1.5");
          })
          .catch(() => {
            document.getElementById("loading").textContent = "";
          });
        </script>
        </body>
        </html>
        """
    }
}
