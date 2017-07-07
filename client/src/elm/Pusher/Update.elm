port module Pusher.Update exposing (update, subscription)

import Config.Model exposing (BackendUrl)
import Pusher.Model exposing (..)


{-| Login to pusher.
-}
port pusherLogin : PusherConfig -> Cmd msg


{-| Logout from pusher.
-}
port pusherLogout : () -> Cmd msg


{-| Receive pusher errors.
-}
port pusherError : (PusherError -> msg) -> Sub msg


{-| Receive pusher state changes.
-}
port pusherState : (String -> msg) -> Sub msg


{-| Receive notice of upcoming connection attempts.
-}
port pusherConnectingIn : (Int -> msg) -> Sub msg


{-| Subscription to connection status.
-}
subscription : Sub Msg
subscription =
    Sub.batch
        [ pusherError HandleError
        , pusherState HandleStateChange
        , pusherConnectingIn HandleConnectingIn
        ]


update : BackendUrl -> Msg -> Model -> ( Model, Cmd Msg )
update backendUrl msg model =
    case msg of
        HandleConnectingIn delay ->
            let
                connectionStatus =
                    case model.connectionStatus of
                        Connecting _ ->
                            Connecting (Just delay)

                        Unavailable _ ->
                            Unavailable (Just delay)

                        _ ->
                            model.connectionStatus
            in
                ( { model | connectionStatus = connectionStatus }
                , Cmd.none
                )

        HandleError error ->
            -- We could consider keeping only X number of errors
            ( { model | errors = error :: model.errors }
            , Cmd.none
            )

        HandleStateChange state ->
            let
                connectionStatus =
                    case state of
                        "intialized" ->
                            Initialized

                        "connecting" ->
                            Connecting Nothing

                        "connected" ->
                            Connected

                        "unavailable" ->
                            Unavailable Nothing

                        "failed" ->
                            Failed

                        "disconnected" ->
                            Disconnected

                        _ ->
                            Other state
            in
                ( { model | connectionStatus = connectionStatus }
                , Cmd.none
                )

        ShowErrorModal ->
            ( { model | showErrorModal = True }
            , Cmd.none
            )

        HideErrorModal ->
            ( { model | showErrorModal = False }
            , Cmd.none
            )

        Login (PusherKey pusherKey) (AccessToken accessToken) ->
            let
                pusherConfig =
                    { key = pusherKey
                    , authEndpoint = backendUrl ++ "/api/pusher_auth?access_token=" ++ accessToken
                    }
            in
                ( model
                , pusherLogin pusherConfig
                )

        Logout ->
            ( model, pusherLogout () )
