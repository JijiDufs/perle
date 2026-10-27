import Foundation
import Supabase

/// Client Supabase unique de l'app Pearl Inc.
/// La clé « publishable » est faite pour être embarquée dans l'app : la sécurité
/// repose sur les règles RLS de la base, pas sur le secret de cette clé.
enum Backend {
    static let url = URL(string: "https://ywyiidsldgfkguivuvox.supabase.co")!
    static let publishableKey = "sb_publishable_5dtk7ii53ELxdzQdfe4Z_Q_VQ_jxFmc"

    /// L'e-mail vérifié du compte connecté est-il dans la liste des inscrits d'avant la sortie ?
    /// La liste reste sur le serveur : la fonction `is_early_signup` ne répond que oui ou non (false hors ligne).
    static func isEarlySignup() async -> Bool {
        (try? await supabase.rpc("is_early_signup").execute().value) ?? false
    }
}

let supabase = SupabaseClient(
    supabaseURL: Backend.url,
    supabaseKey: Backend.publishableKey
)
