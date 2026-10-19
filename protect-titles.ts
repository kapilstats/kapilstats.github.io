// Runs automatically before every `quarto render` (see pre-render in _quarto.yml).
// You never need to edit or run this file yourself.
//
// Why: when reading a .bib file, Pandoc lowercases English titles
// ("Bayesian Inference for the Lindley Distribution" becomes
// "Bayesian inference for the lindley distribution").
// This script copies publications.bib to _publications.bib with every
// title wrapped in an extra pair of braces, which keeps the
// capitalisation exactly as in your .bib file.

const src = await Deno.readTextFile("publications.bib");

const out = src
  // title={Some Title},   ->   title={{Some Title}},
  .replace(/^(\s*(?:book)?title\s*=\s*)\{(?!\{)(.*)\}(\s*,?\s*)$/gim, "$1{{$2}}$3")
  // title = "Some Title",  ->  title = {{Some Title}},
  .replace(/^(\s*(?:book)?title\s*=\s*)"(.*)"(\s*,?\s*)$/gim, "$1{{$2}}$3");

await Deno.writeTextFile("_publications.bib", out);
