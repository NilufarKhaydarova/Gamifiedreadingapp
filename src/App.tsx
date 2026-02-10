import { RouterProvider } from 'react-router';
import { router } from './routes';
import { useEffect } from 'react';
import { getUserProfile } from './lib/storage';

function App() {
  useEffect(() => {
    const profile = getUserProfile();
    if (!profile || !profile.onboardingComplete) {
      window.location.href = '/onboarding';
    }
  }, []);

  return <RouterProvider router={router} />;
}

export default App;