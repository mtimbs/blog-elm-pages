module Api exposing (routes)

import ApiRoute
import Article
import DataSource exposing (DataSource)
import Html exposing (Html)
import Pages
import Route exposing (Route)
import Rss
import Sitemap
import Time


routes :
    DataSource (List Route)
    -> (Html Never -> String)
    -> List (ApiRoute.ApiRoute ApiRoute.Response)
routes getStaticRoutes _ =
    [ rss
        { siteTagline = "Shit Coding Adventures"
        , siteUrl = "https://michaeltimbs.me"
        , title = "Michael Timbs"
        , builtAt = Pages.builtAt
        , indexPage = [ "/blog" ]
        }
        postsDataSource
    , ApiRoute.succeed
        (getStaticRoutes
            |> DataSource.map
                (\allRoutes ->
                    { body =
                        allRoutes
                            |> List.map
                                (\route ->
                                    { path = Route.routeToPath route |> String.join "/"
                                    , lastMod = Nothing
                                    }
                                )
                            |> Sitemap.build { siteUrl = "https://michaeltimbs.me" }
                    }
                )
        )
        |> ApiRoute.literal "sitemap.xml"
        |> ApiRoute.single
    ]


postsDataSource : DataSource.DataSource (List Rss.Item)
postsDataSource =
    Article.allMetadata
        |> DataSource.map
            (List.map
                (\( route, article ) ->
                    { title = article.title
                    , description = article.description
                    , url =
                        route
                            |> Route.routeToPath
                            |> String.join "/"
                    , categories = []
                    , author = "Michael Timbs"
                    , pubDate = Rss.Date article.published
                    , content = Nothing
                    , contentEncoded = Nothing
                    , enclosure = Nothing
                    }
                )
            )


rss :
    { siteTagline : String
    , siteUrl : String
    , title : String
    , builtAt : Time.Posix
    , indexPage : List String
    }
    -> DataSource.DataSource (List Rss.Item)
    -> ApiRoute.ApiRoute ApiRoute.Response
rss options itemsRequest =
    ApiRoute.succeed
        (itemsRequest
            |> DataSource.map
                (\items ->
                    { body =
                        Rss.generate
                            { title = options.title
                            , description = options.siteTagline
                            , url = options.siteUrl ++ "/" ++ String.join "/" options.indexPage
                            , lastBuildTime = options.builtAt
                            , generator = Just "Michael Timbs"
                            , items = items
                            , siteUrl = options.siteUrl
                            }
                    }
                )
        )
        |> ApiRoute.literal "blog/feed.xml"
        |> ApiRoute.single
