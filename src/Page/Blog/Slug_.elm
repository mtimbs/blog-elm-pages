module Page.Blog.Slug_ exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob
import Head
import Head.Seo as Seo
import Html exposing (h1, li, text, ul)
import OptimizedDecoder as Decode exposing (Decoder)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
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
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


routes : DataSource (List RouteParams)
routes =
    Glob.succeed RouteParams
        |> Glob.match (Glob.literal "articles/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal "/index.md")
        |> Glob.toDataSource


type alias Data =
    { body : String
    , title : String
    , published : String
    , tags : List String
    }


data : RouteParams -> DataSource Data
data routeParams =
    File.bodyWithFrontmatter blogPostDecoder ("articles/" ++ routeParams.slug ++ "/index.md")


blogPostDecoder : String -> Decoder Data
blogPostDecoder body =
    Decode.map3 (Data body)
        (Decode.field "title" Decode.string)
        (Decode.field "published" Decode.string)
        (Decode.field "tags" tagsDecoder)


tagsDecoder : Decoder (List String)
tagsDecoder =
    Decode.map (String.split ",")
        Decode.string


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Michael Timbs | Blog"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = static.data.title
        }
        |> Seo.website


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = static.routeParams.slug
    , body =
        [ h1 []
            [ text static.data.title ]
        , ul
            []
            (List.map (\tag -> li [] [ text tag ]) static.data.tags)
        , Html.pre []
            [ Html.text static.data.body ]
        ]
    }
