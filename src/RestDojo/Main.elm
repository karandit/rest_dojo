module RestDojo.Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (placeholder, value, disabled)
import Html.Events exposing (onClick, on, targetValue)
import Html.App

import Json.Decode as Json

import RestDojo.Types exposing (..)
import RestDojo.Games.GameIntroduceYourself as Game1
import RestDojo.Games.Cluedo.GameDontCheat as Game2

-- MAIN ----------------------------------------------------------------------------------------------------------------
main : Program Never
main =
      Html.App.program {
        init = initModel,
        update = update,
        view = view,
        subscriptions = \_ -> Sub.none}

-- MODEL ---------------------------------------------------------------------------------------------------------------
type Game =
  IntroGame Game1.Model
  | DontCheatGame Game2.Model

type GameMsg =
  IntroGameMsg Game1.Msg
  | DontCheatGameMsg Game2.Msg

type alias Tile = TileDescriptor Game

allTiles : List Tile
allTiles = [
  Game1.tileDescriptor IntroGame
  , Game2.tileDescriptor DontCheatGame
 ]

type Screen  =
  MainScreen
  | GameScreen Game

type alias Model = {
  nextId : Int,
  playerUrl: String,
  players: List Player,
  screen: Screen
}

initModel : (Model, Cmd Msg)
initModel = {
  nextId = 3,
  playerUrl = "",
  players = [Player 0 "http://localhost:3001", Player 1 "http://localhost:3002", Player 2 "http://localhost:3003"],
  screen = MainScreen
 } ! []

-- UPDATE --------------------------------------------------------------------------------------------------------------
type Msg =
  EditNewPlayerUrl String
  | AddPlayer
  | RemovePlayer Int
  | SelectTile Tile
  | BackToMain
  | PlayGame Game GameMsg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case Debug.log "Main" msg of
    EditNewPlayerUrl url                  -> {model | playerUrl = url} ! []
    AddPlayer                             -> {model | players =  (Player model.nextId model.playerUrl) :: model.players
                                                    , playerUrl = ""
                                                    , nextId = model.nextId + 1} ! []
    RemovePlayer id                       -> {model | players = List.filter (\p -> p.id /= id) model.players} ! []
    BackToMain                            -> {model | screen = MainScreen } ! []
    SelectTile tile                       -> {model | screen = GameScreen (tile.initGame model.players)} ! []
    PlayGame game gameMsg                 ->
            let
              (newGame, newCmd) = updateGame gameMsg game
            in
              {model | screen = GameScreen newGame} ! [newCmd]

updateGame : GameMsg -> Game -> (Game, Cmd Msg)
updateGame msg game =
  case (msg, game) of
      (IntroGameMsg gameMsg, IntroGame gameModel)         ->
                            let
                              (newGameModel, newGameCmd) = Game1.update gameMsg gameModel
                              _ = Debug.log "intro newGameCmd" newGameCmd
                              newGame = IntroGame newGameModel
                              newCmd = Cmd.map (\newGameMsg -> PlayGame newGame (IntroGameMsg newGameMsg)) newGameCmd
                            in
                              (newGame, newCmd)
      (DontCheatGameMsg gameMsg, DontCheatGame gameModel) ->
                            let
                              (newGameModel, newGameCmd) = Game2.update gameMsg gameModel
                              newGame = DontCheatGame newGameModel
                            in
                              (newGame, Cmd.none) --map (PlayGame newGame DontCheatGameMsg) newGameCmd)
      (_, _) -> Debug.crash "TODO"

-- VIEW ----------------------------------------------------------------------------------------------------------------
view : Model -> Html Msg
view model =
  case model.screen of
    MainScreen -> viewMainScreen model
    GameScreen game -> viewGameScreen game

viewMainScreen : Model -> Html Msg
viewMainScreen model =
    div [] [
        div [] (List.map (\player -> div [] [text player.url, button [onClick (RemovePlayer player.id)] [text "Remove"]]) model.players),
        input [placeholder "URL", value model.playerUrl, on "input" (Json.map EditNewPlayerUrl targetValue)] [],
        button [onClick AddPlayer] [text "Add"],
        hr [] [],
        div [] (List.map (viewTile model) allTiles)
    ]

viewTile : Model -> Tile -> Html Msg
viewTile model tile =
    button [onClick (SelectTile tile), disabled (tile.isDisabled model.players)] [text tile.title]

viewGameScreen : Game -> Html Msg
viewGameScreen game =
  div [] [
    button [onClick BackToMain] [text "Back"],
    span [] [text "fuck"], --TODO game.title],
    hr [] [],
    Html.App.map (PlayGame game) (viewGame game)
  ]

viewGame : Game -> Html GameMsg
viewGame game =
  case game of
    IntroGame model      -> Game1.view model |> Html.App.map IntroGameMsg
    DontCheatGame model  -> Game2.view model |> Html.App.map DontCheatGameMsg
