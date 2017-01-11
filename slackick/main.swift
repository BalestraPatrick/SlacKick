#!/usr/bin/swift

import Foundation

class Slackick {

    typealias CompletionBlock = (Data?, URLResponse?, Error?) -> ()

    private let token = "YOUR_TOKEN"
    private let user = "SLACK_USERNAME"
    private let usersURL = "https://slack.com/api/users.list"
    private let listURL = "https://slack.com/api/channels.list"
    private let kickURL = "https://slack.com/api/channels.kick"
    private let inviteURL = "https://slack.com/api/channels.invite"

    init() {
        listUsers()
    }

    /// List all the users in the Slack group.
    private func listUsers() {
        var usersComponents = URLComponents(string: usersURL)!
        usersComponents.queryItems = [
            URLQueryItem(name: "token", value: token),
        ]
        sendRequest(url: usersComponents.url!) { data, response, error in
            let dictionary = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
            let members = dictionary["members"] as! Array<Dictionary<String, Any>>

            for member in members {
                let name = member["name"] as! String
                if name == self.user {
                    let id = member["id"] as! String
                    self.listUserChannels(id: id)
                }
            }
        }
    }

    private func listUserChannels(id: String) {
        var listComponents = URLComponents(string: listURL)!
        listComponents.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "exclude_archived", value: "1"),
            URLQueryItem(name: "user", value: id)
        ]
        sendRequest(url: listComponents.url!) { data, response, error in
            let dictionary = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
            let channels = dictionary["channels"] as! Array<Dictionary<String, Any>>

            for channel in channels {
                let members = channel["members"] as! Array<String>
                if members.contains(id) {
                    let channelId = channel["id"] as! String
                    print("User \(self.user) is in channel #\(channel["name"]!), slackicking now...")
                    self.kickUser(id: id, channelId: channelId)
                }
            }
        }
    }

    private func kickUser(id: String, channelId: String) {
        var kickComponents = URLComponents(string: kickURL)!
        kickComponents.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "channel", value: channelId),
            URLQueryItem(name: "user", value: id)
        ]
        sendRequest(url: kickComponents.url!) { data, response, error in
            self.inviteUser(id: id, channelId: channelId)
        }
    }

    private func inviteUser(id: String, channelId: String) {
        var kickComponents = URLComponents(string: inviteURL)!
        kickComponents.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "channel", value: channelId),
            URLQueryItem(name: "user", value: id)
        ]
        sendRequest(url: kickComponents.url!) { data, response, error in
            keepAlive = false
        }
    }

    private func sendRequest(url: URL, completion: @escaping CompletionBlock) {
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
        task.resume()
    }
}

var keepAlive = true
let slackick = Slackick()
let runLoop = RunLoop.current
while keepAlive && runLoop.run(mode: RunLoopMode.defaultRunLoopMode, before: NSDate(timeIntervalSinceNow: 0.1) as Date) {}
