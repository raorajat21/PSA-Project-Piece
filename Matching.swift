
//  Matchings.swift


import SwiftUI

public class Agent: ObservableObject, Identifiable, Equatable {
    public static func == (lhs: Agent, rhs: Agent) -> Bool {
        lhs.id == rhs.id
    }

    let emoji: String

    let rankings: [String]

    public var id: String { self.emoji }

    init(emoji: String, rankings: [String]) {
        self.emoji = emoji
        self.rankings = rankings
    }
} 

public class Proposing: Agent {
    @Published var proposed: [String] = []
    @Published var accepted: String?

    public static func girl(_ rankings: [Receiving] = []) -> Proposing {
        return Proposing(emoji: "👧",
                         rankings: rankings.map { $0.id })
    }

    public static func boy(_ rankings: [Receiving] = []) -> Proposing {
        return Proposing(emoji: "👦",
                         rankings: rankings.map { $0.id })
    }

    public static func woman(_ rankings: [Receiving] = []) -> Proposing {
        return Proposing(emoji: "👩‍💻",
                         rankings: rankings.map { $0.id })
    }

    public static func man(_ rankings: [Receiving] = []) -> Proposing {
        return Proposing(emoji: "👱",
                         rankings: rankings.map { $0.id })
    }
}

public class Receiving: Agent {
    @Published var received: [String] = []
    @Published var accepted: String?

    public static func dog(_ rankings: [Proposing] = []) -> Receiving {
        return Receiving(emoji: "🐶",
                         rankings: rankings.map { $0.id })
    }

    public static func cat(_ rankings: [Proposing] = []) -> Receiving {
        return Receiving(emoji: "🐱",
                         rankings: rankings.map { $0.id })
    }

    public static func rabbit(_ rankings: [Proposing] = []) -> Receiving {
        return Receiving(emoji: "🐰",
                         rankings: rankings.map { $0.id })
    }

    public static func bird(_ rankings: [Proposing] = []) -> Receiving {
        return Receiving(emoji: "🐦",
                         rankings: rankings.map { $0.id })
    }
}

public class Matchings: ObservableObject {

    @Published var proposing: [Proposing] = []
    @Published var receiving: [Receiving] = []

    public init(humans: [Proposing], animals: [Receiving]) {
        self.proposing = humans
        self.receiving = animals
    }

    public static var preview: Matchings {
        let matchings = Matchings(humans: [
            .boy([
                .cat(), .dog(), .rabbit()
            ]),
            .woman([
                .cat(), .dog(), .rabbit()
            ]),
            .girl([
                .cat(), .dog(), .rabbit()
            ])

        ], animals: [
            .cat([
                .woman(), .boy(), .girl()
            ]),
            .dog([
                .woman(), .boy(), .girl()
            ]),
            .rabbit([
                .woman(), .boy(), .girl()
            ])
        ])
        return matchings
    }

    public func match(_ proposing: Proposing, with receiving: Receiving) {
        if let previousReceiving = self.receiving.first(where: { $0.id == proposing.accepted }),
           previousReceiving.accepted == proposing.id {
            previousReceiving.accepted = nil
        }
        if let previousProposing = self.proposing.first(where: { $0.id == receiving.accepted }),
           previousProposing.accepted == receiving.id {
            previousProposing.accepted = nil
        }
        self.proposing.first(where: { proposing == $0 })?
            .accepted = receiving.id
        self.receiving.first(where: { receiving == $0 })?
            .accepted = proposing.id
        self.blocking.removeAll()
    }

    public func calculateBlockingEdges() {
        for prop in self.proposing {
            for rec in prop.rankings.prefix(while: { $0 != prop.accepted }) {
                let receiving = self.receiving.first(where: { $0.id == rec })!
                let matchedIndex = receiving.accepted.flatMap {
                    receiving.rankings.firstIndex(of: $0)
                } ?? .max
                if matchedIndex > (receiving.rankings.firstIndex(of: prop.id) ?? .max) {
                    self.blocking.append((prop, receiving))
                }
            }
        }
        if blocking.isEmpty {
            self.completed = true
        }
    }

    private var nextCheck: Int = 0

    public func firstFreeHuman() -> Proposing? {
        let prop = (self.proposing.dropFirst(nextCheck) + self.proposing)
            .first(where: { $0.accepted == nil })
        if let prop = prop {
            nextCheck = self.proposing.firstIndex(of: prop)! + 1
        }
        DispatchQueue.main.async {
            self.line = 0
            self.selected = (prop, nil)
        }
        sleep(1)
        return prop
    }

    public func firstUnproposedAnimal(for human: Proposing) -> Receiving? {
        for id in human.rankings {
            let animal = self.receiving.first(where: { $0.id == id })
            DispatchQueue.main.async {
                self.line = 1
                self.selected = (human, animal)
            }
            sleep(1)
            if !human.proposed.contains(id) {
                return animal
            }
        }
        return nil
    }

    public func propose(_ human: Proposing, to animial: Receiving) -> Bool {
        DispatchQueue.main.async {
            self.line = 2
            self.selected = (animial, human)
        }
        sleep(1)
        let matchedRank = animial.accepted.flatMap(animial.rankings.firstIndex(of:)) ?? .max
        let rank = animial.rankings.firstIndex(of: human.id) ?? .max
        if matchedRank > rank {
            DispatchQueue.main.async {
                self.accepting = animial
                if let previousProposing = self.proposing.first(where: { $0.id == animial.accepted }),
                   previousProposing.accepted == animial.id {
                    previousProposing.accepted = nil
                }
                animial.accepted = human.id
                animial.received.append(human.id)
            }
            sleep(1)
            return true
        } else {
            DispatchQueue.main.async {
                self.rejecting = animial
                animial.received.append(human.id)
            }
            sleep(1)
            return false
        }
    }

    public func accepted(_ human: Proposing, by animial: Receiving) {
        DispatchQueue.main.async {
            self.line = 3
            self.selected = (human, animial)
            self.accepting = nil
            human.accepted = animial.id
            human.proposed.append(animial.id)
        }
        sleep(1)
    }

    public func rejected(_ human: Proposing, by animial: Receiving) {
        DispatchQueue.main.async {
            self.line = 4
            self.selected = (human, animial)
            self.rejecting = nil
            human.proposed.append(animial.id)
        }
        sleep(1)
    }


    public func finished() {
        DispatchQueue.main.async {
            self.completed = true
            self.line = 5
        }
        sleep(3)
        DispatchQueue.main.async {
            self.completed = false
            self.line = 0
        }
    }


    @Published public var selected: (Agent?, Agent?) = (nil, nil)

    @Published public var accepting: Receiving?

    @Published public var rejecting: Receiving?

    @Published public var blocking: [(Agent, Agent)] = []

    @Published public var completed: Bool = false

    @Published var line: Int?

    @Published var isRanked = false

    public func showRankings() {
        self.isRanked = true
    }

}

struct MatchPreference: PreferenceKey {
    static var defaultValue: [String: Anchor<CGPoint>] = [:]

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
public struct MatchingsView: View {

    @StateObject public var model: Matchings

    @Namespace var namespace

    public init(_ model: Matchings = .preview) {
        self._model = StateObject(wrappedValue: model)
    }

    public var body: some View {
        VStack {
            HStack {
                ForEach(model.proposing) { agent in
                    Spacer()
                    ProposingView(agent: agent,
                                  namespace: namespace)
                    Spacer()
                }
            }
            Spacer()
            HStack  {
                ForEach(model.receiving) { agent in
                    Spacer()
                    ReceivingView(agent: agent,
                                  namespace: namespace)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 40)
        .backgroundPreferenceValue(MatchPreference.self, { value in
            GeometryReader { proxy in
                ForEach(model.proposing) { agent in
                    if let source = value[agent.id] {
                        ForEach(agent.rankings, id: \.self) { other in
                            if let sink = value[other] {
                                self.line(from: agent,
                                          to: other,
                                          in: proxy,
                                          start: source,
                                          end: sink)
                            }
                        }
                    }
                }
            }
        })
        .background(Color.white)
        //.environmentObject(self.model)
        .withanimation(.default) {
             value: offset
        }
    }

    func line(from proposing: Proposing,
              to receiving: String,
              in proxy: GeometryProxy,
              start: Anchor<CGPoint>,
              end: Anchor<CGPoint>) -> some View {
        let start = proxy[start]
        let end = proxy[end]

        let receiving = model.receiving.first(where: { $0.id == receiving })!

        let width: CGFloat
        let color: Color
        var isBlocking = model.blocking
            .contains(where: { $0 == (proposing, receiving) })
        if isBlocking {
            color = .red
            width = 4
        } else if proposing.accepted == receiving.id,
           receiving.accepted == proposing.id {
            width = 4
            color = .green
            isBlocking = model.completed
        } else if receiving.received.contains(proposing.id),
                  proposing.proposed.contains(receiving.id) {
            width = 2
            color = .red
        } else {
            width = 2
            color = .black
        }
        return ZStack {
            Path({ path in
                path.move(to: start.moved(20, towards: end))
                if model.isRanked {
                    path.addLine(to: start.moved(40, towards: end))
                    path.move(to: start.moved(80, towards: end))
                    path.addLine(to: end.moved(80, towards: start))
                    path.move(to: end.moved(40, towards: start))
                }
                path.addLine(to: end.moved(20, towards: start))


            })
            .stroke(color, style: .init(lineWidth: isBlocking ? width + 2 : width,
                                        lineCap: .round,
                                        lineJoin: .round))
            .withanimation(
                isBlocking
                    ? Animation
                    .default
                    .repeatForever(autoreverses: true)
                    : .default
            ) {
                value: offset
            }

            if model.isRanked {
                ProposingRank(proposing: proposing,
                              receiving: receiving,
                              namespace: namespace)
                    .position(start.moved(60, towards: end))

                ReceivingRank(receiving: receiving,
                              proposing: proposing,
                              namespace: namespace)
                    .position(end.moved(60, towards: start))
            }
        }

    }
}

struct ProposingRank: View {
    @ObservedObject var proposing: Proposing
    @ObservedObject var receiving: Receiving

    var namespace: Namespace.ID

    @EnvironmentObject var model: Matchings

    var rank: String {
        "\(proposing.rankings.firstIndex(of: receiving.id)! + 1)"
    }

    var isSelected: Bool {
        model.selected == (proposing, receiving)
    }

    var color: Color {
        if proposing.accepted == receiving.id {
            return .green
        } else if proposing.proposed.contains(receiving.id) {
            return .red
        }
        return .black
    }

    var body: some View {
        Text(rank)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .animation(.default)
            .padding(8)
            .background(Group {
                if isSelected {
                    Circle()
                        .stroke(color, style: StrokeStyle(lineWidth: 3))
                        .matchedGeometryEffect(id: "circle",
                                               in: namespace)
                }
            })
    }
}

extension Matchings: CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        let view = MatchingsView(self)
        let hosting = NSHostingView(rootView: view)
        hosting.setFrameSize(.init(width: 500, height: 300))
        return hosting
    }
}

struct ReceivingRank: View {
    @ObservedObject var receiving: Receiving
    @ObservedObject var proposing: Proposing

    var namespace: Namespace.ID

    @EnvironmentObject var model: Matchings

    var rank: String {
        "\(receiving.rankings.firstIndex(of: proposing.id)! + 1)"
    }

    var isSelected: Bool {
        model.selected == (receiving, proposing)
    }

    var color: Color {
        if receiving.accepted == proposing.id {
            return .green
        } else if receiving.received.contains(proposing.id) {
            return .red
        }
        return .black
    }

    var body: some View {
        Text(rank)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .animation(.default)
            .padding(8)
            .background(Group {
                if isSelected {
                    Circle()
                        .stroke(color, style: StrokeStyle(lineWidth: 3))
                        .matchedGeometryEffect(id: "circle",
                                               in: namespace)
                }
            })

    }
}

struct ProposingView: View {
    @ObservedObject var agent: Proposing

    var namespace: Namespace.ID

    @EnvironmentObject var model: Matchings

    var body: some View {


        Text(agent.emoji)
            .font(.system(size: 30))
            .frame(width: 30, height: 30)
            .scaleEffect(isActive ? 1.2 : 1)
            .withanimation(
                isActive
                    ? Animation
                    .default
                    .repeatForever(autoreverses: true)
                    : .default
            ){
                value: offset
            }
            .anchorPreference(key: MatchPreference.self,
                              value: .center,
                              transform: { anchor in
                                [agent.id: anchor]
                              })
            .onTapGesture {
                self.model.selected = (agent, nil)
                self.model.blocking.removeAll()
                self.model.completed = false
            }
    }

    var isSelected: Bool {
        model.selected.0 == agent && model.selected.1 == nil
    }
}

struct ReceivingView: View {
    @ObservedObject var agent: Receiving

    var namespace: Namespace.ID

    @EnvironmentObject var model: Matchings

    var body: some View {
        Text(agent.emoji)
            .font(.system(size: 30))
            .frame(width: 30, height: 30, alignment: .center)
            .scaleEffect(isActive ? 1.2 : 1)
            .withanimation(
                isActive
                    ? Animation
                    .default
                    .offset(x: 0, y: 0)
                    .repeatForever(autoreverses: true)
                    :.default
            ){
                 offset +=0.0
            }
            .shakeEffect(
                model.rejecting == agent || model.accepting == agent || isSelected,
                vertical: model.rejecting != agent
            )
            .anchorPreference(key: MatchPreference.self,
                              value: .center,
                              transform: { anchor in
                                [agent.id: anchor]
                              })
            .onTapGesture {
                if let proposing = model.selected.0 as? Proposing,
                   model.selected.1 == nil {
                    self.model.match(proposing, with: agent)
                    model.selected = (self.agent, nil)
                    self.model.blocking.removeAll()
                    self.model.completed = false
                    if !self.model.proposing.contains(where: { $0.accepted == nil }) {
                        model.calculateBlockingEdges()
                    }
                } else {
                    self.model.rejecting = self.agent
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if self.model.rejecting == self.agent {
                            self.model.rejecting = nil
                        }
                    }
                }
            }
    }

    var isSelected: Bool {
        model.selected.0 == agent && model.selected.1 == nil
    }

    var isActive: Bool {
        (model.completed && agent.accepted != nil)
    }

}


struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 6
    var shakesPerUnit = 3
    var animatableData: CGFloat

    var active: Bool

    var vertical: Bool

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard active else {
            return .init()
        }
        let translation = self.amount * sin(self.animatableData * .pi * CGFloat(self.shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(
                                    translationX: vertical ? 0 : translation,

                                    y: vertical ? translation : 0))
    }
}

public extension View {
    func shakeEffect(_ flag: Bool,
                     vertical: Bool = false) -> some View {
        self.modifier(ShakeEffect(animatableData: flag ? 1 : 0,
                                  active: flag,
                                  vertical: vertical))
    }
}


extension CGPoint {
    func moved(_ distance: CGFloat, towards other: CGPoint) -> CGPoint {
        let v = CGPoint(
            x: other.x - self.x,
            y: other.y - self.y
        )
        let u = CGPoint(
            x: v.x / sqrt(pow(v.x, 2) + pow(v.y, 2)),
            y: v.y / sqrt(pow(v.x, 2) + pow(v.y, 2))
        )
        return CGPoint(
            x: self.x + u.x * distance,
            y: self.y + u.y * distance
        )

    }
}
struct Matchings_Previews: PreviewProvider {
    static var previews: some View {
        MatchingsView()
            .previewLayout(.fixed(width: 500, height: 500))
    }
}
