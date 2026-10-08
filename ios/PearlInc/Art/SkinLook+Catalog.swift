import PearlCore

extension SkinLook {
    /// L'habit d'un skin du catalogue.
    init(_ skin: AppSkin) {
        self.init(style: skin.style, shellLight: skin.shellLight, shellDark: skin.shellDark,
                  nacreLight: skin.nacreLight, nacreShade: skin.nacreShade, rim: skin.rim)
    }
}
