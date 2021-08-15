module StructuredData exposing (article)

import Json.Encode as Encode
import Pages.Url


article :
    { title : String
    , description : String
    , url : String
    , imageUrl : Pages.Url.Url
    , datePublished : String
    }
    -> Encode.Value
article info =
    Encode.object
        [ ( "@context", Encode.string "http://schema.org/" )
        , ( "@type", Encode.string "Article" )
        , ( "headline", Encode.string info.title )
        , ( "description", Encode.string info.description )
        , ( "image", Encode.string (Pages.Url.toString info.imageUrl) )
        , ( "url", Encode.string info.url )
        , ( "datePublished", Encode.string info.datePublished )
        ]
