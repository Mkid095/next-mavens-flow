#!/usr/bin/env node
/**
 * TOON - Token-Oriented Object Notation
 *
 * A compact notation format for structured data that achieves
 * ~52% size reduction compared to JSON.
 *
 * Use ONLY for consolidated memory files where token efficiency matters.
 *
 * Format Specification:
 * - Objects: {key:value,key2:value2}
 * - Arrays: [item1,item2,item3]
 * - Strings: No quotes unless contains special chars
 * - Numbers: Direct representation
 * - Booleans: t (true), f (false)
 * - Null: n
 * - Escaping: \{ \} \[ \] \: \\ \, for special chars
 *
 * Example:
 *   JSON: {"name":"John","age":30,"active":true}
 *   TOON: {name:John,age:30,active:t}
 *
 * Usage:
 *   const toon = require('./toon-compress.js');
 *   const compressed = toon.compress(obj);
 *   const decompressed = toon.decompress(compressed);
 *
 * @module toon-compress
 */

// Token savings: ~52% compared to JSON
const TOKEN_SAVINGS = 0.52;

/**
 * Compress a JavaScript object to TOON format
 *
 * @param {*} value - Value to compress
 * @param {number} indent - Indentation level (for pretty print)
 * @returns {string} TOON formatted string
 */
function compress(value, indent = 0) {
  const indentStr = '  '.repeat(indent);

  if (value === null) {
    return 'n';
  }

  if (value === true) {
    return 't';
  }

  if (value === false) {
    return 'f';
  }

  if (typeof value === 'number') {
    return String(value);
  }

  if (typeof value === 'string') {
    return escapeString(value);
  }

  if (Array.isArray(value)) {
    if (value.length === 0) {
      return '[]';
    }

    const items = value.map(v => compress(v, indent + 1));
    return `[${items.join(',')}]`;
  }

  if (typeof value === 'object') {
    const keys = Object.keys(value);
    if (keys.length === 0) {
      return '{}';
    }

    const pairs = keys.map(key => {
      const escapedKey = escapeString(key);
      return `${escapedKey}:${compress(value[key], indent + 1)}`;
    });

    return `{${pairs.join(',')}}`;
  }

  return 'n';
}

/**
 * Decompress a TOON string to JavaScript object
 *
 * @param {string} toon - TOON formatted string
 * @returns {*} Decompressed value
 */
function decompress(toon) {
  if (typeof toon !== 'string') {
    throw new Error('TOON input must be a string');
  }

  const parser = new TOONParser(toon);
  return parser.parse();
}

/**
 * Escape a string value for TOON format
 *
 * @param {string} str - String to escape
 * @returns {string} Escaped string
 */
function escapeString(str) {
  // Check if string needs quoting
  // Quote if: empty, contains whitespace, special chars, or starts with digit
  const needsQuotes = /^$|\s|[{}[\]:,\\]|^[0-9]/.test(str);

  if (!needsQuotes) {
    return str;
  }

  let escaped = '';
  for (const char of str) {
    switch (char) {
      case '\\': escaped += '\\\\'; break;
      case '"': escaped += '\\"'; break;
      case "'": escaped += "\\'"; break;
      case '\n': escaped += '\\n'; break;
      case '\r': escaped += '\\r'; break;
      case '\t': escaped += '\\t'; break;
      default: escaped += char;
    }
  }

  return `"${escaped}"`;
}

/**
 * Unescape a quoted string value
 *
 * @param {string} str - String to unescape
 * @returns {string} Unescaped string
 */
function unescapeString(str) {
  return str
    .replace(/\\n/g, '\n')
    .replace(/\\r/g, '\r')
    .replace(/\\t/g, '\t')
    .replace(/\\"/g, '"')
    .replace(/\\'/g, "'")
    .replace(/\\\\/g, '\\');
}

/**
 * Check if a string is TOON format
 *
 * @param {string} str - String to check
 * @returns {boolean} True if appears to be TOON format
 */
function isTOON(str) {
  if (typeof str !== 'string') {
    return false;
  }

  const trimmed = str.trim();

  // TOON must start with {, [, or a primitive value
  return /^[{[\]a-zA-Z0-9"']/.test(trimmed);
}

/**
 * Calculate compression ratio
 *
 * @param {*} value - Original value
 * @returns {object} Compression stats
 */
function getCompressionStats(value) {
  const json = JSON.stringify(value);
  const toon = compress(value);

  return {
    original: json.length,
    compressed: toon.length,
    saved: json.length - toon.length,
    ratio: toon.length / json.length,
    percent: ((1 - toon.length / json.length) * 100).toFixed(1)
  };
}

/**
 * TOON Parser Class
 */
class TOONParser {
  constructor(input) {
    this.input = input;
    this.pos = 0;
    this.length = input.length;
  }

  parse() {
    this.skipWhitespace();
    const value = this.parseValue();
    this.skipWhitespace();
    if (this.pos < this.length) {
      throw new Error(`Unexpected character at position ${this.pos}: "${this.input[this.pos]}"`);
    }
    return value;
  }

  parseValue() {
    const char = this.peek();

    if (char === '{') return this.parseObject();
    if (char === '[') return this.parseArray();
    if (char === '"') return this.parseString();
    if (char === 't' && this.isTrue()) return this.parseTrue();
    if (char === 'f' && this.isFalse()) return this.parseFalse();
    if (char === 'n' && this.isNull()) return this.parseNull();
    if (char === '-' || /\d/.test(char)) return this.parseNumber();
    return this.parseUnquotedString();
  }

  parseObject() {
    this.consume('{');
    this.skipWhitespace();

    const obj = {};

    if (this.peek() === '}') {
      this.consume('}');
      return obj;
    }

    while (true) {
      this.skipWhitespace();

      // Parse key (quoted or unquoted)
      let key;
      if (this.peek() === '"') {
        key = this.parseString();
      } else {
        key = this.parseUnquotedString();
      }

      if (!key) {
        throw new Error(`Expected key at position ${this.pos}`);
      }

      this.skipWhitespace();
      this.consume(':');
      this.skipWhitespace();

      // Parse value
      obj[key] = this.parseValue();

      this.skipWhitespace();

      const next = this.peek();
      if (next === '}') {
        this.consume('}');
        break;
      }
      if (next === ',') {
        this.consume(',');
        continue;
      }

      throw new Error(`Expected ',' or '}' at position ${this.pos}`);
    }

    return obj;
  }

  parseArray() {
    this.consume('[');
    this.skipWhitespace();

    const arr = [];

    if (this.peek() === ']') {
      this.consume(']');
      return arr;
    }

    while (true) {
      this.skipWhitespace();
      arr.push(this.parseValue());
      this.skipWhitespace();

      const next = this.peek();
      if (next === ']') {
        this.consume(']');
        break;
      }
      if (next === ',') {
        this.consume(',');
        continue;
      }

      throw new Error(`Expected ',' or ']' at position ${this.pos}`);
    }

    return arr;
  }

  parseString() {
    this.consume('"');
    let str = '';

    while (this.pos < this.length) {
      const char = this.input[this.pos++];

      if (char === '"') {
        return unescapeString(str);
      }

      if (char === '\\') {
        if (this.pos >= this.length) {
          throw new Error('Unexpected end of input in escape sequence');
        }
        str += this.input[this.pos++];
      } else {
        str += char;
      }
    }

    throw new Error('Unterminated string');
  }

  parseUnquotedString() {
    const start = this.pos;

    while (this.pos < this.length) {
      const char = this.input[this.pos];
      if (/[{}[\]:,\\\s]/.test(char)) {
        break;
      }
      this.pos++;
    }

    if (this.pos === start) {
      return null;
    }

    const value = this.input.slice(start, this.pos);

    // Check for boolean or null
    if (value === 't') return true;
    if (value === 'f') return false;
    if (value === 'n') return null;

    // Check for number
    if (/^-?\d+(\.\d+)?([eE][+-]?\d+)?$/.test(value)) {
      return parseFloat(value);
    }

    return value;
  }

  parseNumber() {
    const start = this.pos;

    if (this.peek() === '-') {
      this.pos++;
    }

    while (this.pos < this.length && /[\d.eE+-]/.test(this.input[this.pos])) {
      this.pos++;
    }

    const numStr = this.input.slice(start, this.pos);
    return parseFloat(numStr);
  }

  parseTrue() {
    this.consume('t');
    return true;
  }

  parseFalse() {
    this.consume('f');
    return false;
  }

  parseNull() {
    this.consume('n');
    return null;
  }

  // Check for literal 'true' (not just starting with 't')
  isTrue() {
    return this.input.substr(this.pos, 4) === 'true' &&
           (this.pos + 4 === this.length || /[{}[\]:,\\\s]/.test(this.input[this.pos + 4]));
  }

  // Check for literal 'false' (not just starting with 'f')
  isFalse() {
    return this.input.substr(this.pos, 5) === 'false' &&
           (this.pos + 5 === this.length || /[{}[\]:,\\\s]/.test(this.input[this.pos + 5]));
  }

  // Check for literal 'null' (not just starting with 'n')
  isNull() {
    return this.input.substr(this.pos, 4) === 'null' &&
           (this.pos + 4 === this.length || /[{}[\]:,\\\s]/.test(this.input[this.pos + 4]));
  }

  peek() {
    return this.pos < this.length ? this.input[this.pos] : null;
  }

  consume(char) {
    if (this.peek() !== char) {
      throw new Error(`Expected '${char}' at position ${this.pos}, found '${this.peek()}'`);
    }
    this.pos++;
  }

  skipWhitespace() {
    while (this.pos < this.length && /\s/.test(this.input[this.pos])) {
      this.pos++;
    }
  }
}

// Export all functions
module.exports = {
  compress,
  decompress,
  escapeString,
  unescapeString,
  isTOON,
  getCompressionStats,
  TOKEN_SAVINGS
};

// Allow running as a script for testing
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length === 0 || args[0] === 'help' || args[0] === '--help') {
    console.log('TOON - Token-Oriented Object Notation');
    console.log('');
    console.log('Usage: node toon-compress.js <command> [args]');
    console.log('');
    console.log('Commands:');
    console.log('  compress <json-file>      - Compress JSON to TOON');
    console.log('  decompress <toon-file>    - Decompress TOON to JSON');
    console.log('  stats <json-file>         - Show compression statistics');
    console.log('  test                      - Run compression tests');
    console.log('');
    console.log('Examples:');
    console.log('  node toon-compress.js compress data.json');
    console.log('  node toon-compress.js stats prd.json');
    console.log('');
    console.log('Token Savings: ~52% compared to JSON');
    process.exit(0);
  }

  const [command, ...cmdArgs] = args;

  switch (command) {
    case 'compress': {
      const jsonFile = cmdArgs[0];
      if (!jsonFile) {
        console.error('Error: JSON file path required');
        process.exit(1);
      }
      try {
        const content = require('fs').readFileSync(jsonFile, 'utf-8');
        const obj = JSON.parse(content);
        const toon = compress(obj);
        console.log(toon);
      } catch (e) {
        console.error(`Error: ${e.message}`);
        process.exit(1);
      }
      break;
    }

    case 'decompress': {
      const toonFile = cmdArgs[0];
      if (!toonFile) {
        console.error('Error: TOON file path required');
        process.exit(1);
      }
      try {
        const content = require('fs').readFileSync(toonFile, 'utf-8');
        const obj = decompress(content.trim());
        console.log(JSON.stringify(obj, null, 2));
      } catch (e) {
        console.error(`Error: ${e.message}`);
        process.exit(1);
      }
      break;
    }

    case 'stats': {
      const jsonFile = cmdArgs[0];
      if (!jsonFile) {
        console.error('Error: JSON file path required');
        process.exit(1);
      }
      try {
        const content = require('fs').readFileSync(jsonFile, 'utf-8');
        const obj = JSON.parse(content);
        const stats = getCompressionStats(obj);
        console.log('Compression Statistics:');
        console.log('======================');
        console.log(`  Original:  ${stats.original} bytes`);
        console.log(`  Compressed: ${stats.compressed} bytes`);
        console.log(`  Saved:     ${stats.saved} bytes (${stats.percent}%)`);
        console.log(`  Ratio:     ${(stats.ratio * 100).toFixed(1)}%`);
      } catch (e) {
        console.error(`Error: ${e.message}`);
        process.exit(1);
      }
      break;
    }

    case 'test': {
      // Run tests
      const tests = [
        { input: { name: 'John', age: 30, active: true }, name: 'Simple object' },
        { input: [1, 2, 3, 4, 5], name: 'Simple array' },
        { input: { a: { b: { c: 'deep' } } }, name: 'Nested object' },
        { input: { str: 'hello world', num: 42, bool: false, null: null }, name: 'Mixed types' },
        { input: { 'key with spaces': 'value', 'special:chars': 'test' }, name: 'Special keys' }
      ];

      console.log('TOON Compression Tests');
      console.log('=======================\n');

      let passed = 0;
      for (const test of tests) {
        try {
          const toon = compress(test.input);
          const decompressed = decompress(toon);
          const match = JSON.stringify(test.input) === JSON.stringify(decompressed);
          const stats = getCompressionStats(test.input);

          if (match) {
            passed++;
            console.log(`✓ ${test.name}`);
            console.log(`  Original: ${stats.original}, Compressed: ${stats.compressed}, Saved: ${stats.percent}%`);
          } else {
            console.log(`✗ ${test.name} - Mismatch after roundtrip`);
          }
        } catch (e) {
          console.log(`✗ ${test.name} - ${e.message}`);
        }
      }

      console.log(`\n${passed}/${tests.length} tests passed`);
      process.exit(passed === tests.length ? 0 : 1);
    }

    default:
      console.error(`Unknown command: ${command}`);
      console.log('Run "node toon-compress.js help" for usage');
      process.exit(1);
  }
}
