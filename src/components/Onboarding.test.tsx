import { describe, it, expect, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { Onboarding } from './Onboarding';
import { ProtectedRoute } from './ProtectedRoute';
import { getUserProfile } from '../lib/storage';
import { renderAt, seedProfile } from '../test/utils';
import { createMemoryRouter, RouterProvider } from 'react-router';
import { render } from '@testing-library/react';

function fillStep1({ age = '25', education = 'masters', books = '12' } = {}) {
  fireEvent.change(screen.getByPlaceholderText('Enter your age'), { target: { value: age } });
  fireEvent.change(screen.getByRole('combobox'), { target: { value: education } });
  fireEvent.change(screen.getByPlaceholderText('e.g., 12'), { target: { value: books } });
}

describe('Onboarding', () => {
  beforeEach(() => localStorage.clear());

  it('keeps Continue disabled until age, education and books/year are filled', () => {
    renderAt(<Onboarding />, '/onboarding');
    const cont = screen.getByRole('button', { name: 'Continue' });
    expect(cont).toBeDisabled();
    fillStep1();
    expect(cont).toBeEnabled();
  });

  it('completes the full flow, saves the profile and goes to upload', () => {
    const { router } = renderAt(<Onboarding />, '/onboarding');
    fillStep1();
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));

    expect(screen.getByText('Favorite Genres')).toBeInTheDocument();
    const start = screen.getByRole('button', { name: 'Get Started' });
    expect(start).toBeDisabled();

    fireEvent.click(screen.getByRole('button', { name: 'Mystery' }));
    fireEvent.click(screen.getByRole('button', { name: 'Poetry' }));
    fireEvent.click(screen.getByRole('button', { name: 'Poetry' })); // toggle off
    fireEvent.click(start);

    expect(getUserProfile()).toEqual({
      age: 25,
      education: 'masters',
      booksPerYear: 12,
      favoriteGenres: ['Mystery'],
      onboardingComplete: true,
    });
    expect(router.state.location.pathname).toBe('/upload');
  });

  it('shows recommendations matching reading frequency', () => {
    renderAt(<Onboarding />, '/onboarding');
    fillStep1({ books: '3' });
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));
    expect(screen.getByText(/The Alchemist/)).toBeInTheDocument();
  });

  it('Back returns to step 1', () => {
    renderAt(<Onboarding />, '/onboarding');
    fillStep1();
    fireEvent.click(screen.getByRole('button', { name: 'Continue' }));
    fireEvent.click(screen.getByRole('button', { name: 'Back' }));
    expect(screen.getByText('Welcome to Booklify!')).toBeInTheDocument();
  });

  it.fails('BUG: a user who reads 0 books per year cannot continue', () => {
    renderAt(<Onboarding />, '/onboarding');
    fillStep1({ books: '0' });
    expect(screen.getByRole('button', { name: 'Continue' })).toBeEnabled();
  });
});

describe('ProtectedRoute', () => {
  beforeEach(() => localStorage.clear());

  const mount = () => {
    const router = createMemoryRouter(
      [
        { path: '/onboarding', element: <div>onboarding page</div> },
        { path: '/', element: <ProtectedRoute />, children: [{ index: true, element: <div>secret</div> }] },
      ],
      { initialEntries: ['/'] },
    );
    render(<RouterProvider router={router} />);
    return router;
  };

  it('redirects to onboarding when there is no profile', () => {
    const router = mount();
    expect(router.state.location.pathname).toBe('/onboarding');
  });

  it('shows the page when onboarding is complete', () => {
    seedProfile();
    const router = mount();
    expect(router.state.location.pathname).toBe('/');
    expect(screen.getByText('secret')).toBeInTheDocument();
  });
});
