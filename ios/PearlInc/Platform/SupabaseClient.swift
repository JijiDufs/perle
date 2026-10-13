import Foundation
import Supabase

/// Client Supabase unique de l'app Pearl Inc.
/// La clé « publishable » est faite pour être embarquée dans l'app : la sécurité
/// repose sur les règles RLS de la base, pas sur le secret de cette clé.
enum Backend {
    static let url = URL(string: "https://ywyiidsldgfkguivuvox.supabase.co")!
    static let publishableKey = "sb_publishable_5dtk7ii53ELxdzQdfe4Z_Q_VQ_jxFmc"
}

let supabase = SupabaseClient(
    supabaseURL: Backend.url,
    supabaseKey: Backend.publishableKey
)
