import { createHash } from 'node:crypto';
import { openSync, readSync, writeSync, closeSync } from 'node:fs';

const fd = openSync(process.argv[2], 'r+');
try {
  const prefix = Buffer.alloc(16);
  readSync(fd, prefix, 0, prefix.length, 0);
  const headerSize = prefix.readUInt32LE(4);
  const headerLength = prefix.readUInt32LE(12);
  const headerBuffer = Buffer.alloc(headerSize);
  readSync(fd, headerBuffer, 0, headerSize, 8);
  const header = JSON.parse(headerBuffer.subarray(8, 8 + headerLength).toString());
  const entry = header.files['.vite'].files.build.files['main-CLu1A25j.js'];
  const offset = 8 + headerSize + Number(entry.offset);
  const js = Buffer.alloc(entry.size);
  readSync(fd, js, 0, js.length, offset);
  const hash = data => createHash('sha256').update(data).digest('hex');
  if (hash(js) !== '8aedee047ec0a078e65b24dc917c64ad544220395e773feb6740f4447008a495') {
    throw new Error('Unexpected ChatGPT marketplace implementation');
  }

  const start = js.indexOf('async function Hne(e,t){');
  const copyEnd = js.indexOf('async function ps(e){', start);
  const executorStart = js.indexOf('async function xc(', copyEnd);
  const end = js.indexOf('async function Sc(', executorStart);
  if (start < 0 || copyEnd < 0 || executorStart < 0 || end < 0 ||
      js.indexOf('async function Hne(e,t){', start + 1) >= 0) {
    throw new Error('Cannot locate bundled plugin copy functions');
  }
  const original = js.subarray(start, end).toString();
  const copy = js.subarray(start, copyEnd).toString();
  const executor = js.subarray(executorStart, end).toString();
  const patchedCopy = 'async function Hne(e,t){await k.default.cp(e,t,{recursive:!0,verbatimSymlinks:!0});await yne("chmod",["-R","u+w",t])}';
  const patchedExecutor = executor.replace(
    'await k.default.cp(n.cwd,e,{recursive:!0})',
    'await yne("chmod",["-R","u+w",e]).catch(()=>{}),await k.default.cp(n.cwd,e,{recursive:!0}),await yne("chmod",["-R","u+w",e])',
  );
  if (patchedExecutor === executor) throw new Error('Cannot locate executor plugin copy');
  // Preserve ASAR offsets and integrity while making both Nix-store copies writable.
  const replacement = Buffer.from(original.replace(copy, patchedCopy).replace(executor, patchedExecutor));
  if (replacement.length > end - start) throw new Error('Marketplace patch exceeds original size');
  replacement.copy(js, start);
  js.fill(0x20, start + replacement.length, end);
  entry.integrity.hash = hash(js);
  entry.integrity.blocks = Array.from(
    { length: Math.ceil(js.length / entry.integrity.blockSize) },
    (_, i) => hash(js.subarray(i * entry.integrity.blockSize, (i + 1) * entry.integrity.blockSize)),
  );
  const newHeader = Buffer.from(JSON.stringify(header));
  if (newHeader.length !== headerLength) throw new Error('Marketplace patch changed ASAR header size');
  writeSync(fd, js, 0, js.length, offset);
  writeSync(fd, newHeader, 0, newHeader.length, 16);
} finally {
  closeSync(fd);
}
