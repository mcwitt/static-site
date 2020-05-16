let prelude = ./resume/resume/prelude.dhall

let lib = ./resume/resume/lib/package.dhall

let types = prelude.mkTypes Text

in    { basics = lib.content.basics ⫽ { name = None types.Name }
      , profiles =
          let p = lib.content.profiles

          in  p.empty ⫽ p.homepage ⫽ p.linkedin ⫽ p.github
      , headline = Some "Data Scientist & Software Engineer"
      , sections =
          let s = lib.sections

          in  [ { heading = "Experience", content = s.work }
              , { heading = "Skills", content = s.skills }
              , { heading = "Education", content = s.education }
              ]
      }
    : types.Resume
