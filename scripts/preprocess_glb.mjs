import { readFile, writeFile } from 'node:fs/promises';
import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { dequantize } from '@gltf-transform/functions';
import { MeshoptDecoder } from 'meshoptimizer';

const peopleModels = [
  'assets/models/people/citizen_bryce.glb',
  'assets/models/people/citizen_remy.glb',
  'assets/models/people/citizen_shannon.glb',
  'assets/models/people/citizen_sophie.glb',
  'assets/models/people/mixamo_animation_library.glb',
];

await MeshoptDecoder.ready;
const io = new NodeIO()
  .registerExtensions(ALL_EXTENSIONS)
  .registerDependencies({ 'meshopt.decoder': MeshoptDecoder });

for (const file of peopleModels) {
  await readFile(file);
  const document = await io.read(file);
  await document.transform(dequantize());

  for (const extension of document.getRoot().listExtensionsUsed()) {
    if (extension.extensionName === 'EXT_meshopt_compression') {
      extension.dispose();
    }
  }

  const output = await io.writeBinary(document);
  await writeFile(file, output);
  console.log(`Prepared Godot-compatible model: ${file}`);
}
