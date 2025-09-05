//
//  MarkdownMathView.swift
//  coursiva
//
//  Created by Z1 on 10.07.2025.
//

import SwiftUI
import WebKit

struct MarkdownMathView: UIViewRepresentable {
    let markdownText: String
    @Binding var dynamicHeight: CGFloat
    var backgroundColor: Color? = nil

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        webView.configuration.userContentController.add(context.coordinator, name: "mathJaxFinished")
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Encode markdown as base64 to safely pass into the HTML/JS context
        let markdownBase64 = Data(markdownText.utf8).base64EncodedString()

        let bgColorHex = backgroundColor?.toHex() ?? "#121212"

        let fullHTML = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <!-- Marked.js for GitHub Flavored Markdown (GFM) with tables -->
          <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
          <!-- DOMPurify to sanitize rendered HTML -->
          <script src="https://cdn.jsdelivr.net/npm/dompurify@3.1.6/dist/purify.min.js"></script>
          <script>
            window.MathJax = {
              tex: {
                inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
                displayMath: [['$$','$$'], ['\\\\[', '\\\\]']]
              },
              svg: { fontCache: 'global' },
              startup: {
                pageReady: () => {
                  return MathJax.startup.defaultPageReady().then(() => {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mathJaxFinished) {
                      window.webkit.messageHandlers.mathJaxFinished.postMessage("done");
                    }
                  });
                }
              }
            };
          </script>
          <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
          <!-- highlight.js CDN -->
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
          <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/swift.min.js"></script>
          <style>
            body {
              font-family: -apple-system, sans-serif;
              font-size: 16px;
              background-color: \(bgColorHex);
              color: white;
              margin: 0;
              padding: 0;
            }
            h1 { font-size: 1.3em; margin: 0.6em 0 0.3em 0; }
            h2 { font-size: 1.15em; margin: 0.5em 0 0.25em 0; }
            h3 { font-size: 1.05em; margin: 0.4em 0 0.2em 0; }
            h4, h5, h6 { font-size: 1em; margin: 0.3em 0 0.15em 0; }
            img {
              max-width: 100%;
            }
            pre code {
              display: block;
              max-width: 100vw;
              max-height: 40vh;
              overflow-x: auto;
              overflow-y: auto;
              white-space: pre;
              font-size: 0.95em;
              border-radius: 8px;
              background: #222;
              -webkit-user-select: text;
              user-select: text;
            }
            .table-scroll { width: 100%; overflow-x: auto; -webkit-overflow-scrolling: touch; }
            table { border-collapse: collapse; width: auto; min-width: 100%; margin: 1em 0; font-size: 0.95em; }

            th, td {
              border: 1px solid #444;
              padding: 8px 10px;
              text-align: left;
              vertical-align: top;
            }

            th {
              background-color: #333;
              font-weight: bold;
            }
            tr:nth-child(even) {
              background-color: #1e1e1e;
            }
            /* Prefer horizontal scroll but allow controlled wrapping on non-first columns */
            .table-scroll td, .table-scroll th { white-space: normal; word-break: break-word; overflow-wrap: anywhere; }
            /* First column: compact, no wrap to avoid vertical stretching of short terms */
            .table-scroll table td:first-child, .table-scroll table th:first-child {
              min-width: 140px;
              max-width: 200px;
              white-space: nowrap;
            }
            /* Other columns: reasonable min/max with wrapping */
            .table-scroll table td:not(:first-child), .table-scroll table th:not(:first-child) {
              min-width: 180px;
              max-width: 420px;
              white-space: normal;
              word-break: break-word;
              overflow-wrap: anywhere;
            }
          </style>
        </head>
        <body>
        <div id="content"></div>
        <script>
          (function() {
            try {
              // Configure marked for GFM with tables and line breaks
              if (window.marked) {
                marked.setOptions({ gfm: true, breaks: true, headerIds: true, mangle: false });
              }

              const b64 = '\(markdownBase64)';
              const bin = atob(b64);
              const bytes = new Uint8Array(bin.length);
              for (let i = 0; i < bin.length; i++) { bytes[i] = bin.charCodeAt(i); }
              const md = new TextDecoder('utf-8').decode(bytes);
              const rawHtml = window.marked ? marked.parse(md) : md;
              const safeHtml = window.DOMPurify ? DOMPurify.sanitize(rawHtml) : rawHtml;
              const container = document.getElementById('content');
              container.innerHTML = safeHtml;

              // Wrap tables in a horizontally scrollable container
              Array.from(container.querySelectorAll('table')).forEach(function(tbl) {
                const wrapper = document.createElement('div');
                wrapper.className = 'table-scroll';
                tbl.parentNode.insertBefore(wrapper, tbl);
                wrapper.appendChild(tbl);
              });

              if (window.hljs) { hljs.highlightAll(); }

              // Re-typeset MathJax after injecting content
              if (window.MathJax && window.MathJax.typesetPromise) {
                MathJax.typesetPromise().then(() => {
                  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mathJaxFinished) {
                    window.webkit.messageHandlers.mathJaxFinished.postMessage("done");
                  }
                });
              } else {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mathJaxFinished) {
                  window.webkit.messageHandlers.mathJaxFinished.postMessage("done");
                }
              }
            } catch (e) {
              const container = document.getElementById('content');
              container.innerHTML = '<p>Error rendering markdown</p>';
              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mathJaxFinished) {
                window.webkit.messageHandlers.mathJaxFinished.postMessage("done");
              }
            }
          })();
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(fullHTML, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(dynamicHeight: $dynamicHeight)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        @Binding var dynamicHeight: CGFloat

        init(dynamicHeight: Binding<CGFloat>) {
            _dynamicHeight = dynamicHeight
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // No longer update height here, wait for MathJax
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "mathJaxFinished" {
                // MathJax finished rendering, now measure height
                if let webView = message.webView {
                    webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                        let buffer: CGFloat = 12 // Add a small buffer to avoid clipping
                        if let height = result as? CGFloat {
                            self.dynamicHeight = height + buffer
                        } else if let height = result as? Double {
                            self.dynamicHeight = CGFloat(height) + buffer
                        } else if let height = result as? Int {
                            self.dynamicHeight = CGFloat(height) + buffer
                        }
                    }
                }
            }
        }
    }
}

// Helper to convert SwiftUI Color to hex string
extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
