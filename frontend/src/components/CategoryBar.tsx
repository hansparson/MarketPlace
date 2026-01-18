import { useState, useEffect } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import client from '../api/client';
import {
    HomeIcon,
    TruckIcon,
    DevicePhoneMobileIcon,
    ComputerDesktopIcon,
    SparklesIcon,
    CpuChipIcon,
    TrophyIcon,
    SwatchIcon,
    HomeModernIcon,
    MapIcon,
    SquaresPlusIcon,
    WrenchIcon
} from '@heroicons/react/24/outline';
import { Squares2X2Icon, ChevronDownIcon, ChevronUpIcon } from '@heroicons/react/24/solid';

interface Category {
    id: string;
    name: string;
}

const CategoryBar = () => {
    const [categories, setCategories] = useState<Category[]>([]);
    const [searchParams] = useSearchParams();
    const activeCat = searchParams.get('cat');
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);

    // Close dropdown when clicking outside
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            const target = event.target as HTMLElement;
            if (!target.closest('.category-dropdown-container')) {
                setIsDropdownOpen(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    useEffect(() => {
        const fetchCategories = async () => {
            try {
                const res = await client.get('/categories');
                if (res.data && res.data.message_data) {
                    setCategories(res.data.message_data);
                }
            } catch (err) {
                console.error("Failed to load categories", err);
            }
        };
        fetchCategories();
    }, []);

    const getIcon = (name: string) => {
        const lower = name.toLowerCase();
        if (lower.includes('mobil')) return TruckIcon;
        if (lower.includes('motor')) return WrenchIcon; // Using Wrench for Motor context or could use Truck
        if (lower.includes('rumah')) return HomeModernIcon;
        if (lower.includes('tanah')) return MapIcon;
        if (lower.includes('kendaraan')) return TruckIcon;
        if (lower.includes('hp') || lower.includes('phone') || lower.includes('handphone')) return DevicePhoneMobileIcon;
        if (lower.includes('laptop') || lower.includes('komputer')) return ComputerDesktopIcon;
        if (lower.includes('properti')) return HomeIcon;
        if (lower.includes('elektronik')) return CpuChipIcon;
        if (lower.includes('hobi')) return TrophyIcon;
        if (lower.includes('fashion')) return SwatchIcon;
        if (lower.includes('jasa')) return SquaresPlusIcon;
        return SparklesIcon;
    };

    const popularCategoriesOrdered = [
        "Rumah", "Tanah", "Mobil", "Motor", "Elektronik", "Fashion", "Handphone", "Hobi & Olahraga", "Jasa", "Kendaraan", "Laptop & Komputer"
    ];

    const displayCategories = categories.length > 0
        ? categories.filter(c => popularCategoriesOrdered.some(p => c.name.toLowerCase().includes(p.toLowerCase())))
            .sort((a, b) => {
                const indexA = popularCategoriesOrdered.findIndex(p => a.name.toLowerCase().includes(p.toLowerCase()));
                const indexB = popularCategoriesOrdered.findIndex(p => b.name.toLowerCase().includes(p.toLowerCase()));
                return indexA - indexB;
            })
        : popularCategoriesOrdered.map((name, i) => ({ id: `pop-${i}`, name }));

    return (
        <div className="bg-white pt-2 sm:pt-4 pb-2 border-b border-gray-100 sticky top-[108px] md:top-[96px] z-20">
            <div className="max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8 flex items-center gap-4 sm:gap-6 lg:gap-10">
                {/* All Category Button & Dropdown - Desktop only */}
                <div className="hidden md:block flex-shrink-0 relative category-dropdown-container">
                    <button
                        onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                        className={`flex items-center gap-3 px-6 py-3.5 rounded-2xl font-bold transition-all transform hover:-translate-y-0.5 active:translate-y-0 ${isDropdownOpen || !activeCat ? 'bg-gradient-to-r from-pink-500 to-rose-600 text-white shadow-lg shadow-rose-200' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}
                    >
                        <Squares2X2Icon className={`w-5 h-5 ${isDropdownOpen || !activeCat ? 'text-white/90' : 'text-gray-400'}`} />
                        <span className="tracking-wide text-sm uppercase">All Category</span>
                        {isDropdownOpen ? (
                            <ChevronUpIcon className={`w-4 h-4 text-white/80`} />
                        ) : (
                            <ChevronDownIcon className={`w-4 h-4 text-white/80`} />
                        )}
                    </button>

                    {/* Dropdown Menu */}
                    {isDropdownOpen && (
                        <div className="absolute top-full mt-3 left-0 w-64 bg-white rounded-3xl shadow-2xl border border-gray-100 overflow-hidden py-4 animate-in fade-in slide-in-from-top-5 duration-200">
                            <div className="px-6 pb-3 mb-2 border-b border-gray-50">
                                <span className="text-[10px] font-black text-gray-400 uppercase tracking-[0.2em]">Explore Categories</span>
                            </div>
                            <div className="max-h-[60vh] overflow-y-auto px-2">
                                <Link
                                    to="/"
                                    onClick={() => setIsDropdownOpen(false)}
                                    className={`flex items-center gap-4 px-4 py-3 rounded-2xl transition-all ${!activeCat ? 'bg-rose-50 text-rose-600' : 'text-gray-600 hover:bg-gray-50'}`}
                                >
                                    <Squares2X2Icon className="w-5 h-5 opacity-70" />
                                    <span className="text-sm font-bold">Semua Produk</span>
                                </Link>
                                {categories.sort((a, b) => a.name.localeCompare(b.name)).map(cat => {
                                    const Icon = getIcon(cat.name);
                                    return (
                                        <Link
                                            key={cat.id}
                                            to={`/?cat=${cat.id}`}
                                            onClick={() => setIsDropdownOpen(false)}
                                            className={`flex items-center gap-4 px-4 py-3 rounded-2xl transition-all ${activeCat === cat.id ? 'bg-rose-50 text-rose-600' : 'text-gray-600 hover:bg-gray-50'}`}
                                        >
                                            <Icon className="w-5 h-5 opacity-70" />
                                            <span className="text-sm font-semibold">{cat.name}</span>
                                        </Link>
                                    );
                                })}
                            </div>
                        </div>
                    )}
                </div>

                {/* Categories List */}
                <div className="flex-1 overflow-x-auto scrollbar-hide py-1">
                    <div className="flex items-center gap-6 sm:gap-8 md:gap-12 min-w-max px-1">
                        {displayCategories.map(cat => {
                            const Icon = getIcon(cat.name);
                            const isActive = activeCat === cat.id;
                            return (
                                <Link
                                    key={cat.id}
                                    to={cat.name.includes('Kendaraan') ? `/?q=${encodeURIComponent('Mobil Motor')}` : `/?cat=${cat.id}`}
                                    className="group flex flex-col items-center gap-2 sm:gap-3 min-w-[50px] sm:min-w-[60px] cursor-pointer"
                                >
                                    <div className={`p-1.5 sm:p-2 md:p-1 transition-all duration-300 ${isActive ? 'text-rose-600 scale-110' : 'text-gray-400 group-hover:text-rose-500'}`}>
                                        <Icon className="w-5 h-5 sm:w-6 sm:h-6 md:w-7 md:h-7 stroke-[2] sm:stroke-[1.5]" />
                                    </div>
                                    <span className={`text-[10px] sm:text-xs md:text-sm transition-all text-center whitespace-nowrap ${isActive ? 'text-gray-900 font-black' : 'text-gray-500 group-hover:text-gray-900 font-bold sm:font-semibold'}`}>
                                        {cat.name}
                                    </span>
                                    <div className={`h-0.5 sm:h-1 rounded-full transition-all duration-300 ${isActive ? 'w-full bg-rose-500 opacity-100' : 'w-0 bg-rose-500 opacity-0 group-hover:w-full group-hover:opacity-100'}`}></div>
                                </Link>
                            );
                        })}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CategoryBar;
