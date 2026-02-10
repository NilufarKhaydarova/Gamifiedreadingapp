import { createBrowserRouter } from "react-router";
import { Root } from "./components/Root";
import { Dashboard } from "./components/Dashboard";
import { UploadBook } from "./components/UploadBook";
import { ReadingPlan } from "./components/ReadingPlan";
import { ChatBot } from "./components/ChatBot";
import { Achievements } from "./components/Achievements";
import { Onboarding } from "./components/Onboarding";
import { AudioPlayer } from "./components/AudioPlayer";
import { VoiceChatBot } from "./components/VoiceChatBot";

export const router = createBrowserRouter([
  {
    path: "/onboarding",
    Component: Onboarding,
  },
  {
    path: "/",
    Component: Root,
    children: [
      { index: true, Component: Dashboard },
      { path: "upload", Component: UploadBook },
      { path: "plan", Component: ReadingPlan },
      { path: "chat", Component: VoiceChatBot },
      { path: "achievements", Component: Achievements },
      { path: "audio", Component: AudioPlayer },
    ],
  },
]);