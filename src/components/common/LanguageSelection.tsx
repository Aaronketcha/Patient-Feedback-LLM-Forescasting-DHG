const LanguageSelection = ({ onLanguageSelect }: { onLanguageSelect: (lang: string) => void }) => {
  const languages = [
        { code: 'fr', name: 'Français', flag: '🇫🇷' },
        { code: 'en', name: 'Anglais', flag: '🇬🇧' },
        { code: 'bas', name: 'Bassa', flag: '🇨🇲' },
        { code: 'dua', name: 'Douala', flag: '🇨🇲' },
        { code: 'ew', name: 'Ewondo', flag: '🇨🇲' }
    ];

    return (
        <div className="fixed inset-0 bg-gradient-to-br from-primary to-secondary flex items-center justify-center z-50">
            <div className="bg-white rounded-2xl p-8 shadow-2xl max-w-md w-full mx-4">
                <h2 className="text-2xl font-bold text-center mb-2 text-gray-800">Choisissez votre langue</h2>
                <p className="text-gray-600 text-center mb-8">Sélectionnez la langue pour votre assistant médical</p>

                <div className="space-y-3">
                    {languages.map((lang) => (
                        <button
                            key={lang.code}
                            onClick={() => onLanguageSelect(lang.code)}
                            className="w-full flex items-center space-x-4 p-4 rounded-xl border-2 border-gray-200 hover:border-primary hover:bg-blue-50 transition-all duration-200"
                        >
                            <span className="text-2xl">{lang.flag}</span>
                            <span className="text-lg font-medium text-gray-800">{lang.name}</span>
                        </button>
                    ))}
                </div>
            </div>
        </div>
    );
};

export default LanguageSelection;