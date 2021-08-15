module MarkdownRenderer exposing (renderer)

import Css
import Html.Styled as Html
import Html.Styled.Attributes as Attr exposing (css)
import Markdown.Block as Block
import Markdown.Html
import Markdown.Renderer
import Oembed
import SyntaxHighlight
import Tailwind.Breakpoints as Breakpoints
import Tailwind.Utilities as Tw


renderer : Markdown.Renderer.Renderer (Html.Html msg)
renderer =
    { heading = heading
    , paragraph = Html.p []
    , thematicBreak = Html.hr [] []
    , text = Html.text
    , strong = \content -> Html.strong [ css [ Tw.font_bold ] ] content
    , emphasis = \content -> Html.em [ css [ Tw.italic ] ] content
    , blockQuote = Html.blockquote []
    , codeSpan =
        \content ->
            Html.code
                [ css
                    [ Tw.font_semibold
                    , Tw.font_medium
                    , Css.color (Css.rgb 226 0 124) |> Css.important
                    ]
                ]
                [ Html.text content ]
    , link =
        \{ destination } body ->
            Html.a
                [ Attr.href destination
                , css
                    [ Tw.underline
                    ]
                ]
                body
    , hardLineBreak = Html.br [] []
    , image =
        \image ->
            case image.title of
                Just _ ->
                    Html.img [ Attr.src image.src, Attr.alt image.alt ] []

                Nothing ->
                    Html.img [ Attr.src image.src, Attr.alt image.alt ] []
    , unorderedList =
        \items ->
            Html.ul [ css [ Tw.list_none ] ]
                (items
                    |> List.map
                        (\item ->
                            case item of
                                Block.ListItem task children ->
                                    let
                                        checkbox =
                                            case task of
                                                Block.NoTask ->
                                                    Html.text ""

                                                Block.IncompleteTask ->
                                                    Html.input
                                                        [ Attr.disabled True
                                                        , Attr.checked False
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []

                                                Block.CompletedTask ->
                                                    Html.input
                                                        [ Attr.disabled True
                                                        , Attr.checked True
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []
                                    in
                                    Html.li [] (checkbox :: children)
                        )
                )
    , orderedList =
        \startingIndex items ->
            Html.ol
                (case startingIndex of
                    1 ->
                        [ Attr.start startingIndex ]

                    _ ->
                        []
                )
                (items
                    |> List.map
                        (\itemBlocks ->
                            Html.li [ css [ Tw.list_none ] ]
                                itemBlocks
                        )
                )
    , html =
        Markdown.Html.tag "oembed"
            (\url _ ->
                Oembed.view [] Nothing url
                    |> Maybe.map Html.fromUnstyled
                    |> Maybe.withDefault (Html.div [] [])
            )
            |> Markdown.Html.withAttribute "url"
    , codeBlock = codeBlock
    , table =
        Html.table
            [ css
                []
            ]
    , tableHeader = Html.thead []
    , tableBody = Html.tbody []
    , tableRow = Html.tr []
    , strikethrough =
        \children -> Html.del [] children
    , tableHeaderCell =
        \maybeAlignment ->
            let
                attrs =
                    maybeAlignment
                        |> Maybe.map
                            (\alignment ->
                                case alignment of
                                    Block.AlignLeft ->
                                        "left"

                                    Block.AlignCenter ->
                                        "center"

                                    Block.AlignRight ->
                                        "right"
                            )
                        |> Maybe.map Attr.align
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []
            in
            Html.th attrs
    , tableCell =
        \maybeAlignment ->
            let
                attrs =
                    maybeAlignment
                        |> Maybe.map
                            (\alignment ->
                                case alignment of
                                    Block.AlignLeft ->
                                        "left"

                                    Block.AlignCenter ->
                                        "center"

                                    Block.AlignRight ->
                                        "right"
                            )
                        |> Maybe.map Attr.align
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []
            in
            Html.td attrs
    }


rawTextToId : String -> String
rawTextToId rawText =
    rawText
        |> String.split " "
        |> String.join "-"
        |> String.toLower


heading : { level : Block.HeadingLevel, rawText : String, children : List (Html.Html msg) } -> Html.Html msg
heading { level, rawText, children } =
    case level of
        Block.H1 ->
            Html.h1
                [ css
                    [ Tw.text_3xl
                    , Tw.font_extrabold
                    , Tw.tracking_tight
                    , Tw.text_gray_900
                    , Tw.mb_4
                    , Breakpoints.md [ Tw.leading_3, Tw.text_5xl ]
                    , Breakpoints.sm [ Tw.text_4xl ]
                    ]
                ]
                children

        Block.H2 ->
            Html.h2
                [ Attr.id (rawTextToId rawText)
                , Attr.attribute "name" (rawTextToId rawText)
                , css
                    []
                ]
                [ Html.a
                    [ Attr.href <| "#" ++ rawTextToId rawText
                    , css
                        [ Tw.no_underline |> Css.important
                        ]
                    ]
                    children
                ]

        _ ->
            (case level of
                Block.H1 ->
                    Html.h1

                Block.H2 ->
                    Html.h2

                Block.H3 ->
                    Html.h3

                Block.H4 ->
                    Html.h4

                Block.H5 ->
                    Html.h5

                Block.H6 ->
                    Html.h6
            )
                [ css
                    [ Tw.font_bold
                    , Tw.text_lg
                    , Tw.mt_8
                    , Tw.mb_4
                    ]
                ]
                children


codeBlock : { body : String, language : Maybe String } -> Html.Html msg
codeBlock details =
    SyntaxHighlight.javascript details.body
        |> Result.map (SyntaxHighlight.toBlockHtml (Just 1))
        |> Result.map Html.fromUnstyled
        |> Result.withDefault (Html.pre [] [ Html.code [] [ Html.text details.body ] ])
