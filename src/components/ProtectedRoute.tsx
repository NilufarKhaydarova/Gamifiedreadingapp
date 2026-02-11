import { useEffect } from 'react';
import { useNavigate, Outlet } from 'react-router';
import { getUserProfile } from '../lib/storage';

export function ProtectedRoute() {
  const navigate = useNavigate();

  useEffect(() => {
    const profile = getUserProfile();
    if (!profile || !profile.onboardingComplete) {
      navigate('/onboarding');
    }
  }, [navigate]);

  return <Outlet />;
}
