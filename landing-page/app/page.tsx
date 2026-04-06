import { Footer } from "@/components/layout/Footer";
import { Navbar } from "@/components/layout/Navbar";
import { Features } from "@/components/sections/Features";
import { Hero } from "@/components/sections/Hero";
import { OperatorQuote } from "@/components/sections/OperatorQuote";
import { WaitlistSection } from "@/components/sections/WaitlistSection";

export default function HomePage() {
  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <WaitlistSection />
        <Features />
        <OperatorQuote />
      </main>
      <Footer />
    </>
  );
}
