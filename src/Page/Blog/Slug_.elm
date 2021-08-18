module Page.Blog.Slug_ exposing (Data, Model, Msg, page)

import Article
import Cloudinary
import DataSource exposing (DataSource)
import Date exposing (Date)
import Head
import Head.Seo as Seo
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import MarkdownCodec
import MarkdownRenderer
import OptimizedDecoder
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Path
import Shared
import StructuredData
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { slug : String }


page : Page RouteParams Data
page =
    Page.prerender
        { data = data
        , head = head
        , routes = routes
        }
        |> Page.buildNoState { view = view }


routes : DataSource.DataSource (List RouteParams)
routes =
    Article.blogPostsGlob
        |> DataSource.map
            (List.map
                (\globData ->
                    { slug = globData.slug }
                )
            )


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = static.data.metadata.title
    , body =
        [ div
            [ css
                [ Tw.min_h_screen
                , Tw.w_full
                , Tw.relative
                ]
            ]
            [ div
                [ css
                    [ Tw.pt_16
                    , Tw.pb_16
                    , Tw.px_8
                    , Tw.flex
                    , Tw.flex_col
                    ]
                ]
                [ div
                    [ css
                        [ Bp.md [ Tw.mx_auto ]
                        ]
                    ]
                    [ h1
                        [ css
                            [ Tw.text_center
                            , Tw.text_4xl
                            , Tw.font_bold
                            , Tw.tracking_tight
                            , Tw.mt_2
                            , Tw.mb_8
                            ]
                        ]
                        [ text static.data.metadata.title
                        ]
                    , div
                        [ css
                            [ Tw.prose
                            , Tw.max_w_3xl
                            ]
                        ]
                        static.data.body
                    ]
                ]
            ]
        ]
    }


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    let
        metadata =
            static.data.metadata
    in
    Head.structuredData
        (StructuredData.article
            { title = metadata.title
            , description = metadata.description
            , url = "https://michaeltimbs.me" ++ Path.toAbsolute static.path
            , imageUrl = metadata.image
            , datePublished = Date.toIsoString metadata.published
            }
        )
        :: (Seo.summaryLarge
                { canonicalUrlOverride = Nothing
                , siteName = "Michael Timbs"
                , image =
                    { url = metadata.image
                    , alt = metadata.description
                    , dimensions = Nothing
                    , mimeType = Nothing
                    }
                , description = metadata.description
                , locale = Nothing
                , title = metadata.title
                }
                |> Seo.article
                    { tags = []
                    , section = Nothing
                    , publishedTime = Just (Date.toIsoString metadata.published)
                    , modifiedTime = Nothing
                    , expirationTime = Nothing
                    }
           )


type alias Data =
    { metadata : ArticleMetadata
    , body : List (Html Msg)
    }


data : RouteParams -> DataSource Data
data route =
    MarkdownCodec.withFrontmatter Data
        frontmatterDecoder
        MarkdownRenderer.renderer
        ("articles/" ++ route.slug ++ "/index.md")


type alias ArticleMetadata =
    { title : String
    , description : String
    , published : Date
    , image : Pages.Url.Url
    , draft : Bool
    }


frontmatterDecoder : OptimizedDecoder.Decoder ArticleMetadata
frontmatterDecoder =
    OptimizedDecoder.map5 ArticleMetadata
        (OptimizedDecoder.field "title" OptimizedDecoder.string)
        (OptimizedDecoder.field "description" OptimizedDecoder.string)
        (OptimizedDecoder.field "published"
            (OptimizedDecoder.string
                |> OptimizedDecoder.andThen
                    (\isoString ->
                        Date.fromIsoString isoString
                            |> OptimizedDecoder.fromResult
                    )
            )
        )
        (OptimizedDecoder.field "image" imageDecoder)
        (OptimizedDecoder.field "draft" OptimizedDecoder.bool
            |> OptimizedDecoder.maybe
            |> OptimizedDecoder.map (Maybe.withDefault False)
        )


imageDecoder : OptimizedDecoder.Decoder Pages.Url.Url
imageDecoder =
    OptimizedDecoder.string
        |> OptimizedDecoder.map (\cloudinaryAsset -> Cloudinary.url cloudinaryAsset Nothing 800)
