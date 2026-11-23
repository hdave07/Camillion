(* demo_round.ml

   Owner: Teju (primary), Meira (secondary)

   TEMPORARY stand-in for Bank + Engine so the two endpoints work end to end
   before loader and round engine are merged. Tiers here are placeholders, not
   real rarity data. *)

open Camillion

type prompt = {
  id : string;
  text : string;
  answers : Matcher.entry list;
}

let e name aliases tier = { Matcher.name; aliases; tier }

let prompts =
  [
    {
      id = "fruit";
      text = "Name a fruit";
      answers =
        [
          e "Apple" [] Tier.Sand;
          e "Banana" [] Tier.Sand;
          e "Strawberry" [] Tier.Breeze;
          e "Mango" [] Tier.Breeze;
          e "Pomegranate" [] Tier.Updraft;
          e "Lychee" [ "Litchi" ] Tier.JetStream;
          e "Rambutan" [] Tier.OneInACamillion;
          e "Durian" [] Tier.Interstellar;
        ];
    };
    {
      id = "cornell";
      text = "Name a building on Cornell's campus";
      answers =
        [
          e "Olin Library" [ "Olin" ] Tier.Sand;
          e "Willard Straight Hall" [ "Willard Straight"; "WSH" ] Tier.Sand;
          e "McGraw Tower" [ "McGraw"; "Clocktower"; "Clock Tower" ] Tier.Sand;
          e "Uris Library" [ "Uris" ] Tier.Sand;
          e "Duffield Hall" [ "Duffield" ] Tier.Sand;
          e "Statler Hall" [ "Statler" ] Tier.Sand;
          e "Gates Hall" [ "Gates" ] Tier.Breeze;
          e "Bailey Hall" [ "Bailey" ] Tier.Breeze;
          e "Barton Hall" [ "Barton" ] Tier.Breeze;
          e "Rhodes Hall" [ "Rhodes" ] Tier.Breeze;
          e "Klarman Hall" [ "Klarman" ] Tier.Breeze;
          e "Sage Hall" [ "Sage" ] Tier.Breeze;
          e "Mann Library" [ "Mann" ] Tier.Breeze;
          e "Goldwin Smith Hall" [ "Goldwin Smith" ] Tier.Breeze;
          e "Johnson Museum of Art"
            [ "Johnson Museum"; "Herbert F. Johnson Museum of Art" ]
            Tier.Breeze;
          e "Lynah Rink" [ "Lynah" ] Tier.Breeze;
          e "Schoellkopf Field" [ "Schoellkopf" ] Tier.Breeze;
          e "Day Hall" [] Tier.Updraft;
          e "Ives Hall" [ "Ives" ] Tier.Updraft;
          e "Upson Hall" [ "Upson" ] Tier.Updraft;
          e "Phillips Hall" [ "Phillips" ] Tier.Updraft;
          e "Carpenter Hall" [ "Carpenter" ] Tier.Updraft;
          e "Baker Laboratory" [ "Baker Lab" ] Tier.Updraft;
          e "Physical Sciences Building" [ "PSB" ] Tier.Updraft;
          e "Malott Hall" [ "Malott" ] Tier.Updraft;
          e "Morrill Hall" [ "Morrill" ] Tier.Updraft;
          e "Sage Chapel" [] Tier.Updraft;
          e "Robert Purcell Community Center"
            [ "Robert Purcell"; "RPCC" ]
            Tier.Updraft;
          e "Appel Commons" [ "Appel"; "North Star" ] Tier.Updraft;
          e "Anabel Taylor Hall" [ "Anabel Taylor"; "ATH" ] Tier.JetStream;
          e "Myron Taylor Hall" [ "Myron Taylor" ] Tier.JetStream;
          e "Lincoln Hall" [] Tier.JetStream;
          e "Bradfield Hall" [ "Bradfield" ] Tier.JetStream;
          e "Kennedy Hall" [] Tier.JetStream;
          e "Martha Van Rensselaer Hall" [ "MVR" ] Tier.JetStream;
          e "Hollister Hall" [ "Hollister" ] Tier.JetStream;
          e "Kimball Hall" [] Tier.JetStream;
          e "Snee Hall" [] Tier.JetStream;
          e "Weill Hall" [] Tier.JetStream;
          e "Teagle Hall" [ "Teagle" ] Tier.JetStream;
          e "Balch Hall" [ "Balch" ] Tier.JetStream;
          e "Risley Hall" [ "Risley" ] Tier.JetStream;
          e "Clara Dickson Hall" [ "Dickson" ] Tier.JetStream;
          e "Mary Donlon Hall" [ "Donlon" ] Tier.JetStream;
          e "White Hall" [] Tier.JetStream;
          e "McGraw Hall" [] Tier.JetStream;
          e "Rand Hall" [] Tier.OneInACamillion;
          e "Tjaden Hall" [ "Tjaden" ] Tier.OneInACamillion;
          e "Sibley Hall" [ "Sibley" ] Tier.OneInACamillion;
          e "Milstein Hall" [ "Milstein" ] Tier.OneInACamillion;
          e "Stimson Hall" [ "Stimson" ] Tier.OneInACamillion;
          e "Rockefeller Hall" [] Tier.OneInACamillion;
          e "Clark Hall" [] Tier.OneInACamillion;
          e "Comstock Hall" [ "Comstock" ] Tier.OneInACamillion;
          e "Warren Hall" [] Tier.OneInACamillion;
          e "Fernow Hall" [ "Fernow" ] Tier.OneInACamillion;
          e "Stocking Hall" [] Tier.OneInACamillion;
          e "Caldwell Hall" [ "Caldwell" ] Tier.OneInACamillion;
          e "Uris Hall" [] Tier.OneInACamillion;
          e "Thurston Hall" [] Tier.OneInACamillion;
          e "Fuertes Observatory" [ "Fuertes" ] Tier.Interstellar;
        ];
    };
    {
      id = "disney";
      text = "Name a Disney animated movie";
      answers =
        [
          e "Frozen" [] Tier.Sand;
          e "The Lion King" [] Tier.Sand;
          e "Aladdin" [] Tier.Sand;
          e "Moana" [] Tier.Sand;
          e "Beauty and the Beast" [] Tier.Sand;
          e "The Little Mermaid" [] Tier.Sand;
          e "Cinderella" [] Tier.Sand;
          e "Snow White and the Seven Dwarfs" [ "Snow White" ] Tier.Sand;
          e "Tangled" [] Tier.Sand;
          e "Encanto" [] Tier.Breeze;
          e "Zootopia" [ "Zootropolis" ] Tier.Breeze;
          e "Mulan" [] Tier.Breeze;
          e "Frozen II" [ "Frozen 2" ] Tier.Breeze;
          e "Pocahontas" [] Tier.Breeze;
          e "Bambi" [] Tier.Breeze;
          e "Dumbo" [] Tier.Breeze;
          e "Peter Pan" [] Tier.Breeze;
          e "Lilo & Stitch" [] Tier.Breeze;
          e "Big Hero 6" [ "Big Hero Six" ] Tier.Breeze;
          e "Wreck-It Ralph" [] Tier.Breeze;
          e "Sleeping Beauty" [] Tier.Breeze;
          e "Pinocchio" [] Tier.Breeze;
          e "The Jungle Book" [] Tier.Breeze;
          e "Alice in Wonderland" [] Tier.Breeze;
          e "Hercules" [] Tier.Updraft;
          e "Tarzan" [] Tier.Updraft;
          e "The Princess and the Frog" [] Tier.Updraft;
          e "Ralph Breaks the Internet" [ "Wreck-It Ralph 2" ] Tier.Updraft;
          e "One Hundred and One Dalmatians" [ "101 Dalmatians" ] Tier.Updraft;
          e "Lady and the Tramp" [] Tier.Updraft;
          e "Robin Hood" [] Tier.Updraft;
          e "The Aristocats" [] Tier.Updraft;
          e "Bolt" [] Tier.Updraft;
          e "Raya and the Last Dragon" [ "Raya" ] Tier.Updraft;
          e "Wish" [] Tier.Updraft;
          e "Fantasia" [] Tier.Updraft;
          e "The Hunchback of Notre Dame" [] Tier.Updraft;
          e "The Emperor's New Groove" [] Tier.JetStream;
          e "Atlantis: The Lost Empire" [ "Atlantis" ] Tier.JetStream;
          e "Brother Bear" [] Tier.JetStream;
          e "Meet the Robinsons" [] Tier.JetStream;
          e "The Rescuers" [] Tier.JetStream;
          e "The Fox and the Hound" [] Tier.JetStream;
          e "Oliver & Company" [] Tier.JetStream;
          e "Strange World" [] Tier.JetStream;
          e "Moana 2" [ "Moana II" ] Tier.JetStream;
          e "The Many Adventures of Winnie the Pooh" [ "Winnie the Pooh" ]
            Tier.JetStream;
          e "The Sword in the Stone" [] Tier.JetStream;
          e "Treasure Planet" [] Tier.OneInACamillion;
          e "Chicken Little" [] Tier.OneInACamillion;
          e "Home on the Range" [] Tier.OneInACamillion;
          e "Dinosaur" [] Tier.OneInACamillion;
          e "The Great Mouse Detective" [] Tier.OneInACamillion;
          e "The Black Cauldron" [] Tier.OneInACamillion;
          e "Fantasia 2000" [] Tier.OneInACamillion;
          e "The Rescuers Down Under" [] Tier.OneInACamillion;
          e "The Three Caballeros" [] Tier.OneInACamillion;
          e "Saludos Amigos" [] Tier.OneInACamillion;
          e "Make Mine Music" [] Tier.OneInACamillion;
          e "Fun and Fancy Free" [] Tier.OneInACamillion;
          e "Melody Time" [] Tier.OneInACamillion;
          e "The Adventures of Ichabod and Mr. Toad" [ "Ichabod and Mr. Toad" ]
            Tier.Interstellar;
        ];
    };
  ]

let find id = List.find_opt (fun p -> p.id = id) prompts

(* TEMPORARY stand-in for Saranya's Scoring module. Miles follow the shared
   contract in docs/ARCHITECTURE.md section 5.1; balloon counts are a guess. *)
let score = function
  | Tier.Sand -> (1, 4)
  | Tier.Breeze -> (2, 8)
  | Tier.Updraft -> (3, 16)
  | Tier.JetStream -> (4, 32)
  | Tier.OneInACamillion -> (5, 64)
  | Tier.Interstellar -> (6, 100)
