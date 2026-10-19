// Runs automatically before every `quarto render` (see pre-render in _quarto.yml).
// You never need to edit or run this file yourself.
//
// Writes today's date to _variables.yml. The page footer shows it as
// "Last updated on ..." through {{< var last-updated >}} in _quarto.yml.

const months = ["January", "February", "March", "April", "May", "June", "July",
                "August", "September", "October", "November", "December"];
const today = new Date();
const text = `${today.getDate()} ${months[today.getMonth()]} ${today.getFullYear()}`;

await Deno.writeTextFile("_variables.yml",
  "# Written by last-updated.ts at every render; do not edit.\n" +
  `last-updated: "${text}"\n`);
