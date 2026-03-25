import Foundation

struct EventInput: Codable {
    let title: String?
    let start_date: String?
    let start_time: String?
    let end_date: String?
    let end_time: String?
    let all_day: Bool?
    let location: String?
    let notes: String?
}

func readStdinInput() -> EventInput {
    // Read a single line from stdin (non-blocking for pipe input)
    guard let line = readLine(strippingNewline: true), !line.isEmpty else {
        return EventInput(
            title: nil, start_date: nil, start_time: nil,
            end_date: nil, end_time: nil, all_day: nil,
            location: nil, notes: nil
        )
    }

    do {
        let data = Data(line.utf8)
        let input = try JSONDecoder().decode(EventInput.self, from: data)
        return input
    } catch {
        fputs("JSON parse error: \(error.localizedDescription)\n", stderr)
        return EventInput(
            title: nil, start_date: nil, start_time: nil,
            end_date: nil, end_time: nil, all_day: nil,
            location: nil, notes: nil
        )
    }
}

func parseDate(_ dateStr: String, _ timeStr: String?) -> Date? {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")

    if let timeStr = timeStr, !timeStr.isEmpty {
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: "\(dateStr) \(timeStr)")
    } else {
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateStr)
    }
}
