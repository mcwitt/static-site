import ./. {
  overrides = self: super: {
    ghc = super.ghc // { withPackages = super.ghc.withHoogle; };
    ghcWithPackages = self.ghc.withPackages;
  };
}
