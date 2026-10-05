// Partage d'une image via la feuille de partage du téléphone (Web Share API).
// Sans partage de fichiers (ordinateur, vieux navigateurs) : téléchargement de l'image.
// iOS exige que navigator.share soit appelé directement dans le geste : l'image doit donc
// être prête AVANT le toucher (voir prepareShare).

export type ShareOutcome = 'shared' | 'downloaded' | 'cancelled';

export interface PreparedShare {
  file: File | null;
  ready: Promise<File>;
}

export function prepareShare(render: () => Promise<Blob>, filename: string): PreparedShare {
  const prepared: PreparedShare = { file: null, ready: Promise.resolve(null as unknown as File) };
  prepared.ready = render().then((blob) => {
    prepared.file = new File([blob], filename, { type: blob.type || 'image/png' });
    return prepared.file;
  });
  return prepared;
}

export async function shareFile(prepared: PreparedShare, text: string): Promise<ShareOutcome> {
  // Appel synchrone si l'image est prête : le geste de l'utilisateur est encore valide.
  const file = prepared.file ?? (await prepared.ready);
  if (typeof navigator.canShare === 'function' && navigator.canShare({ files: [file] })) {
    try {
      await navigator.share({ files: [file], text });
      return 'shared';
    } catch (error) {
      if ((error as DOMException).name === 'AbortError') return 'cancelled';
    }
  }
  const url = URL.createObjectURL(file);
  const link = document.createElement('a');
  link.href = url;
  link.download = file.name;
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 10_000);
  return 'downloaded';
}
