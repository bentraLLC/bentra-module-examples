// slugify: CommonJS (require). Bentra installs dependencies with `npm ci` and points NODE_PATH
// at them, which `require` honours and ES module `import` does not.
'use strict';

const fs = require('fs');
const slugify = require('slugify');

const inputs = JSON.parse(fs.readFileSync(process.env.BENTRA_INPUT_FILE, 'utf8'));
const maxLength = inputs.max_length || 63;

let slug = slugify(inputs.text, { lower: true, strict: true }).slice(0, maxLength);
slug = slug.replace(/-+$/, '');
if (!slug) {
    fs.writeFileSync(process.env.BENTRA_OUTPUT_FILE, JSON.stringify({
        error: { code: 'empty_slug', message: 'The text has no letters or digits to keep.' },
    }));
    console.error('The text has no letters or digits to keep.');
    process.exit(1);
}

console.log(`slug: ${slug}`);
fs.writeFileSync(process.env.BENTRA_OUTPUT_FILE, JSON.stringify({ slug }));
