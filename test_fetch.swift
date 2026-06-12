import Foundation

let ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

func testHead() async {
    let url = "https://asurascans.com/"
    var req = URLRequest(url: URL(string: url)!)
    req.httpMethod = "HEAD"
    req.setValue(ua, forHTTPHeaderField: "User-Agent")
    do {
        let (_, response) = try await URLSession.shared.data(for: req)
        print("Final URL: \((response as? HTTPURLResponse)?.url?.absoluteString ?? "none")")
    } catch {
        print("Error: \(error)")
    }
}

let sema = DispatchSemaphore(value: 0)
Task {
    await testHead()
    sema.signal()
}
sema.wait()
