import { Roboto, Roboto_Mono } from "next/font/google";
import "./material.css";

const roboto = Roboto({
  weight: ["300", "400", "500", "700"],
  subsets: ["latin"],
  variable: "--font-roboto",
});

const robotoMono = Roboto_Mono({
  weight: ["400", "500"],
  subsets: ["latin"],
  variable: "--font-roboto-mono",
});

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className={`${roboto.variable} ${robotoMono.variable}`}>
      <link
        href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..0&display=swap"
        rel="stylesheet"
      />
      {children}
    </div>
  );
}
