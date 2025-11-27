import SwiftUI
import SDWebImageSwiftUI

struct ItemDetailView: View {
    let item: ItemBase
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let urlStr = item.detail?.media?.primary, let url = URL(string: urlStr) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                }
                
                Text(item.detail?.title ?? item.ref.name)
                    .font(.title.bold())
                
                if let desc = item.detail?.description {
                    Text(desc)
                        .foregroundColor(.secondary)
                }
                
                if let attrs = item.detail?.attributes, !attrs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Atributos")
                            .font(.headline)
                        ForEach(attrs, id: \.name) { a in
                            HStack {
                                Text(a.name)
                                Spacer()
                                Text(a.value ?? "—")
                                    .foregroundColor(.secondary)
                            }
                            Divider()
                        }
                    }
                    .padding(.vertical)
                }
                
                if let stats = item.detail?.stats, !stats.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Estadísticas")
                            .font(.headline)
                        
                        ForEach(stats, id: \.name) { s in
                            VStack(spacing: 4) {
                                HStack {
                                    Text(s.name)
                                    Spacer()
                                    Text("\(s.value)")
                                        .bold()
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 8)
                                        
                                        // Simple bar visualization relative to a max (arbitrary for now)
                                        // In a real app, we'd calculate max from the list or use a fixed scale.
                                        // Here we just show a full bar for visual effect or random.
                                        // Let's make it full for now as we don't have a relative max.
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue)
                                            .frame(width: geo.size.width, height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
