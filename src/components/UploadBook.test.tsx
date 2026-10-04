import { describe, it, expect, beforeEach, vi } from 'vitest';
import { screen, fireEvent, waitFor } from '@testing-library/react';

vi.mock('../lib/rag', () => ({ ingestBook: vi.fn() }));

import { ingestBook } from '../lib/rag';
import { UploadBook } from './UploadBook';
import { getStoredBook, getProgress } from '../lib/storage';
import { renderAt } from '../test/utils';

function fillDetails() {
  fireEvent.change(screen.getByPlaceholderText('e.g., War and Peace'), { target: { value: 'Dune' } });
  fireEvent.change(screen.getByPlaceholderText('e.g., Leo Tolstoy'), { target: { value: 'Frank Herbert' } });
  fireEvent.change(screen.getByPlaceholderText('e.g., 1225'), { target: { value: '600' } });
  fireEvent.change(screen.getByPlaceholderText('e.g., 30'), { target: { value: '20' } });
}

describe('UploadBook', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.mocked(ingestBook).mockReset();
    vi.mocked(ingestBook).mockResolvedValue({ bookId: 'x', chunksTotal: 1, chunksEmbedded: 1 });
  });

  it('Continue is disabled until text is pasted', () => {
    renderAt(<UploadBook />, '/upload');
    const cont = screen.getByRole('button', { name: 'Continue' });
    expect(cont).toBeDisabled();
    fireEvent.change(screen.getByPlaceholderText(/Paste the full text/), { target: { value: '   ' } });
    expect(cont).toBeDisabled();
    fireEvent.change(screen.getByPlaceholderText(/Paste the full text/), { target: { value: 'Text' } });
    expect(cont).toBeEnabled();
  });

  it('paste → details → creates the book, the reading plan and runs RAG ingestion', async () => {
    const { router } = renderAt(<UploadBook />, '/upload');
    fireEvent.change(screen.getByPlaceholderText(/Paste the full text/), {
      target: { value: 'A desert planet.' },
    });
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));
    expect(screen.getByText('Book Details')).toBeInTheDocument();

    fillDetails();
    fireEvent.click(screen.getByRole('button', { name: 'Create Reading Plan' }));

    await waitFor(() => expect(router.state.location.pathname).toBe('/'));
    expect(getStoredBook()).toMatchObject({
      title: 'Dune',
      author: 'Frank Herbert',
      totalPages: 600,
      content: 'A desert planet.',
    });
    const progress = getProgress()!;
    expect(progress.totalDays).toBe(20);
    expect(progress.dailyPages).toHaveLength(20);
    expect(progress.dailyPages.at(-1)!.end).toBe(600);
    expect(ingestBook).toHaveBeenCalledWith(expect.objectContaining({ title: 'Dune' }), expect.any(Function));
  });

  it('still finishes when RAG ingestion fails (no API keys)', async () => {
    vi.mocked(ingestBook).mockRejectedValue(new Error('No embedding API key found'));
    vi.spyOn(console, 'warn').mockImplementation(() => {});
    const { router } = renderAt(<UploadBook />, '/upload');
    fireEvent.change(screen.getByPlaceholderText(/Paste the full text/), { target: { value: 'x' } });
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));
    fillDetails();
    fireEvent.click(screen.getByRole('button', { name: 'Create Reading Plan' }));

    await waitFor(() => expect(router.state.location.pathname).toBe('/'));
    expect(getStoredBook()?.title).toBe('Dune');
  });

  it('shows the ingestion progress screen while embedding', async () => {
    let finish!: () => void;
    vi.mocked(ingestBook).mockImplementation(async (_b, onProgress) => {
      onProgress?.({ phase: 'embedding', chunksTotal: 4, chunksEmbedded: 1 });
      await new Promise<void>((r) => (finish = r));
      return { bookId: 'x', chunksTotal: 4, chunksEmbedded: 4 };
    });
    renderAt(<UploadBook />, '/upload');
    fireEvent.change(screen.getByPlaceholderText(/Paste the full text/), { target: { value: 'x' } });
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));
    fillDetails();
    fireEvent.click(screen.getByRole('button', { name: 'Create Reading Plan' }));

    expect(await screen.findByText('Embedding passages: 1 / 4')).toBeInTheDocument();
    finish();
  });

  it('uploading a .txt file moves to the details step with its content', async () => {
    const { container } = renderAt(<UploadBook />, '/upload');
    const input = container.querySelector('input[type="file"]') as HTMLInputElement;
    const file = new File(['Chapter 1\nHello'], 'book.txt', { type: 'text/plain' });
    fireEvent.change(input, { target: { files: [file] } });

    expect(await screen.findByText('Book Details')).toBeInTheDocument();
  });

  it('Back from details returns to the upload step', () => {
    renderAt(<UploadBook />, '/upload');
    fireEvent.change(screen.getByPlaceholderText(/Paste the full text/), { target: { value: 'x' } });
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));
    fireEvent.click(screen.getByRole('button', { name: 'Back' }));
    expect(screen.getByText('Upload Your Book')).toBeInTheDocument();
  });

  it('only advertises the file types the picker accepts (.txt)', () => {
    const { container } = renderAt(<UploadBook />, '/upload');
    const input = container.querySelector('input[type="file"]') as HTMLInputElement;
    expect(input.accept).toBe('.txt');
    expect(screen.getByText('Plain text (.txt) files')).toBeInTheDocument();
    expect(screen.queryByText(/\.pdf|\.epub/)).not.toBeInTheDocument();
  });
});
