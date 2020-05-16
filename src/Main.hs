{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Clay ((?), Css, em, pc, px, sym)
import qualified Clay as C
import Control.Lens
import Control.Monad
import Data.Aeson (FromJSON, fromJSON)
import qualified Data.Aeson as Aeson
import qualified Data.Text as T
import Data.Text (Text)
import Development.Shake
import GHC.Generics (Generic)
import Lucid
import Main.Utf8
import Resume (defaultInputSettings, readResume, rootDirectory)
import Resume.Backend.Html (def, renderHtmlBody, renderHtmlStyles)
import Rib (IsRoute, Pandoc)
import qualified Rib
import qualified Rib.Parser.Pandoc as Pandoc
import System.FilePath

-- | Route corresponding to each generated static page.
--
-- The `a` parameter specifies the data (typically Markdown document) used to
-- generate the final page text.
data Route a where
  Route_Index :: Route [(Route Pandoc, Pandoc)]
  Route_Article :: FilePath -> Route Pandoc
  Route_AboutMe :: Route Pandoc
  Route_Resume :: Route (Html ())

-- | The `IsRoute` instance allows us to determine the target .html path for
-- each route. This affects what `routeUrl` will return.
instance IsRoute Route where
  routeFile = \case
    Route_Index ->
      pure "index.html"
    Route_Article srcPath ->
      pure $ "article" </> srcPath -<.> ".html"
    Route_AboutMe ->
      pure "me.html"
    Route_Resume ->
      pure "resume.html"

-- | Main entry point to our generator.
--
-- `Rib.run` handles CLI arguments, and takes three parameters here.
--
-- 1. Directory `content`, from which static files will be read.
-- 2. Directory `dest`, under which target files will be generated.
-- 3. Shake action to run.
--
-- In the shake action you would expect to use the utility functions
-- provided by Rib to do the actual generation of your static site.
main :: IO ()
main = withUtf8 $ do
  Rib.run "content" "dest" generateSite

-- | Shake action for generating the static site
generateSite :: Action ()
generateSite = do
  -- Copy over the static files
  Rib.buildStaticFiles ["static/**"]
  let writeHtmlRoute' :: Html () -> Route a -> a -> Action ()
      writeHtmlRoute' extraHeader r =
        Rib.writeRoute r
          . Lucid.renderText
          . renderPage extraHeader r
      writeHtmlRoute = writeHtmlRoute' mempty
      mkArticle readFn srcPath = do
        let r = Route_Article srcPath
        doc <- Pandoc.parse readFn srcPath
        writeHtmlRoute r doc
        pure (r, doc)
  -- Build individual sources, generating .html for each.
  articles <-
    Rib.forEvery ["posts" </> "*.md"] (mkArticle Pandoc.readMarkdown)
      <> Rib.forEvery ["posts" </> "*.org"] (mkArticle Pandoc.readOrg)
  writeHtmlRoute Route_Index articles
  Pandoc.parse Pandoc.readMarkdown "me.md" >>= writeHtmlRoute Route_AboutMe
  -- Resume
  contentDir <- Rib.ribInputDir
  let settings = defaultInputSettings & rootDirectory .~ contentDir
  resume <- liftIO $ readResume settings (contentDir </> "resume.dhall")
  case renderHtmlBody def resume of
    Right r -> writeHtmlRoute' (Resume.Backend.Html.renderHtmlStyles def) Route_Resume r
    Left e -> fail $ show e

-- | Define your site HTML here
renderPage :: Html () -> Route a -> a -> Html ()
renderPage extraHeader route val = html_ [lang_ "en"] $ do
  head_ $ do
    meta_ [httpEquiv_ "Content-Type", content_ "text/html; charset=utf-8"]
    title_ routeTitle
    style_ [type_ "text/css"] $ C.render pageStyle
    extraHeader
  body_ $ do
    div_ [class_ "header"]
      $ nav_
      $ ul_
      $ do
        li_ $ a_ [href_ "/"] "Home"
        li_ $ a_ [href_ "/me.html"] "About me"
        li_ $ a_ [href_ "/resume.html"] "Resume"
    h1_ routeTitle
    case route of
      Route_Index ->
        div_ $ forM_ val $ \(r, src) ->
          li_ [class_ "pages"] $ do
            let meta = getMeta src
            b_ $ a_ [href_ (Rib.routeUrl r)] $ toHtml $ title meta
            renderMarkdown `mapM_` description meta
      Route_Article _ ->
        article_ $
          Pandoc.render val
      Route_AboutMe ->
        p_ $
          Pandoc.render val
      Route_Resume -> val
  where
    routeTitle :: Html ()
    routeTitle = case route of
      Route_Index -> "Blaaahg"
      Route_Article _ -> toHtml $ title $ getMeta val
      Route_AboutMe -> "About me"
      Route_Resume -> "Matt Wittmann"
    renderMarkdown :: Text -> Html ()
    renderMarkdown =
      Pandoc.render . Pandoc.parsePure Pandoc.readMarkdown

-- | Define your site CSS here
pageStyle :: Css
pageStyle = C.body ? do
  C.margin (em 4) (pc 20) (em 1) (pc 20)
  ".header" ? do
    C.marginBottom $ em 2
  "li.pages" ? do
    C.listStyleType C.none
    C.marginTop $ em 1
    "b" ? C.fontSize (em 1.2)
    "p" ? sym C.margin (px 0)

-- | Metadata in our markdown sources
data SrcMeta
  = SrcMeta
      { title :: Text,
        -- | Description is optional, hence `Maybe`
        description :: Maybe Text
      }
  deriving (Show, Eq, Generic, FromJSON)

-- | Get metadata from Markdown's YAML block
getMeta :: Pandoc -> SrcMeta
getMeta src = case Pandoc.extractMeta src of
  Nothing -> error "No YAML metadata"
  Just (Left e) -> error $ T.unpack e
  Just (Right val) -> case fromJSON val of
    Aeson.Error e -> error $ "JSON error: " <> e
    Aeson.Success v -> v
