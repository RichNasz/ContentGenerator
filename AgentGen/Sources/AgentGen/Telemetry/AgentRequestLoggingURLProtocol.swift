//
//  AgentRequestLoggingURLProtocol.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

#if os(macOS)
import Foundation
import os

/// A `URLProtocol` subclass that intercepts HTTP POST requests made by `LLMClient`,
/// writes the request body to a temp file, and emits an `"HTTPRequest"` OSSignpost event
/// with the file path. The request is then forwarded transparently using a delegate-based
/// `URLSessionDataTask` so SSE streaming (via `AsyncBytes.lines`) continues to work correctly.
///
/// This protocol is only active when registered via `URLSessionConfiguration.protocolClasses`
/// on the session passed to `LLMClient` — it is never registered globally.
final class AgentRequestLoggingURLProtocol: URLProtocol, URLSessionDataDelegate, @unchecked Sendable {

    // MARK: - Shared State

    private static let handledKey = "AgentRequestLoggingHandled"
    private static let signposter = OSSignposter(
        subsystem: "com.rnaszcyn.ContentGenerator.AgentGen",
        category: "OpenResponsesBackend"
    )

    // MARK: - Per-Instance State

    /// Separate session using `.default` config (no logging protocol) to avoid infinite recursion.
    private lazy var forwardingSession = URLSession(
        configuration: .default, delegate: self, delegateQueue: nil
    )
    private var forwardTask: URLSessionDataTask?

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool {
        URLProtocol.property(forKey: handledKey, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        // Write the raw JSON body to a temp file and emit a signpost with its path.
        if let body = request.httpBody {
            let timestamp = Int(Date().timeIntervalSince1970)
            let filename = "agentgen_http_post_\(timestamp).json"
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
            try? body.write(to: url)
            Self.signposter.emitEvent("HTTPRequest", "\(url.path, privacy: .public)")
        }

        // Mark the request as handled, then forward it via the internal session.
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)
        forwardTask = forwardingSession.dataTask(with: mutableRequest as URLRequest)
        forwardTask?.resume()
    }

    override func stopLoading() {
        forwardTask?.cancel()
    }

    // MARK: - URLSessionDataDelegate

    /// Forward the response headers immediately so the upstream consumer sees them without delay.
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }

    /// Forward each data chunk as it arrives so SSE lines are yielded incrementally.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }

    /// Signal completion or failure to the upstream consumer.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}
#endif
