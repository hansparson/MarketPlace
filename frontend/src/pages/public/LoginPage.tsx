import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import client from '../../api/client';
import Navbar from '../../components/Navbar';

interface LoginPageProps {
    type: 'admin' | 'reseller' | 'member';
}

const LoginPage = ({ type }: LoginPageProps) => {
    const navigate = useNavigate();
    const [identifier, setIdentifier] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const isReseller = type === 'reseller';
    const isMember = type === 'member';
    
    const title = isMember ? 'Member Login' : isReseller ? 'Reseller Login' : 'Admin Login';
    const identifierLabel = (isReseller || isMember) ? 'Phone Number' : 'Email Address';
    const identifierPlaceholder = (isReseller || isMember) ? '0812...' : 'admin@example.com';
    const endpoint = isMember ? '/auth/login/member' : isReseller ? '/auth/login/reseller' : '/auth/login/admin';

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        try {
            const payload = (isReseller || isMember)
                ? { phone: identifier, password }
                : { email: identifier, password };

            const res = await client.post(endpoint, payload);

            if (res.data && res.data.message_data && res.data.message_data.token) {
                const token = res.data.message_data.token;
                const role = res.data.message_data.role;
                localStorage.setItem('token', token);
                localStorage.setItem('role', role);

                if (res.data.message_data.user && res.data.message_data.user.referral_code && res.data.message_data.user.referral_code.Valid) {
                    localStorage.setItem('referral_code', res.data.message_data.user.referral_code.String);
                }

                // Redirect based on role
                if (role === 'SUPER_ADMIN' || role === 'ADMIN') {
                    navigate('/admin/dashboard');
                } else {
                    navigate('/');
                }
            }
        } catch (err: any) {
            console.error("Login failed", err);
            if (err.response && err.response.data && err.response.data.message_data) {
                setError(err.response.data.message_data);
            } else {
                setError('Invalid credentials or server error.');
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 flex flex-col">
            <Navbar />

            <div className="flex-grow flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
                <div className="max-w-md w-full space-y-8 bg-white p-8 rounded-2xl shadow-lg border border-gray-100">
                    <div>
                        <div className="flex justify-center mb-4">
                            <div className={`p-4 rounded-full ${isMember ? 'bg-indigo-100' : isReseller ? 'bg-green-100' : 'bg-blue-100'}`}>
                                <svg className={`w-12 h-12 ${isMember ? 'text-indigo-600' : isReseller ? 'text-green-600' : 'text-blue-600'}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                                </svg>
                            </div>
                        </div>
                        <h2 className="text-center text-3xl font-extrabold text-gray-900">
                            {title}
                        </h2>
                        <p className="mt-2 text-center text-sm text-gray-600">
                            {isMember
                                ? "Enter your phone number to access leader features."
                                : isReseller
                                    ? "Enter your phone number to access reseller features."
                                    : "Secure area for administrators."}
                        </p>
                    </div>
                    <form className="mt-8 space-y-6" onSubmit={handleLogin}>
                        <div className="space-y-4">
                            <div>
                                <label htmlFor="identifier" className="block text-sm font-medium text-gray-700 mb-1">
                                    {identifierLabel}
                                </label>
                                <input
                                    id="identifier"
                                    name="identifier"
                                    type={isReseller ? "tel" : "email"}
                                    required
                                    className="appearance-none rounded-lg relative block w-full px-4 py-3 border border-gray-300 placeholder-gray-400 text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                                    placeholder={identifierPlaceholder}
                                    value={identifier}
                                    onChange={(e) => setIdentifier(e.target.value)}
                                />
                            </div>
                            <div>
                                <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
                                    Password
                                </label>
                                <input
                                    id="password"
                                    name="password"
                                    type="password"
                                    required
                                    className="appearance-none rounded-lg relative block w-full px-4 py-3 border border-gray-300 placeholder-gray-400 text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                                    placeholder="Enter your password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                />
                            </div>
                        </div>

                        {error && (
                            <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg text-sm">
                                {error}
                            </div>
                        )}

                        <div>
                            <button
                                type="submit"
                                disabled={loading}
                                className={`group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-lg text-white transition-all ${loading
                                    ? 'bg-gray-400 cursor-not-allowed'
                                    : isMember
                                        ? 'bg-indigo-600 hover:bg-indigo-700 hover:shadow-lg'
                                        : isReseller
                                            ? 'bg-green-600 hover:bg-green-700 hover:shadow-lg'
                                            : 'bg-blue-600 hover:bg-blue-700 hover:shadow-lg'
                                    }`}
                            >
                                {loading ? (
                                    <span className="flex items-center gap-2">
                                        <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none"></circle>
                                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                        </svg>
                                        Signing in...
                                    </span>
                                ) : 'Sign in'}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default LoginPage;
