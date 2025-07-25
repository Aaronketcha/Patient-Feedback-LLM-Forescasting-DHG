import { useState } from 'react';
import ChatPage from '../ChatPage';
import LanguageSelection from '../../components/common/LanguageSelection';

const Home = () => {
    const [isFirstLogin, setIsFirstLogin] = useState(true)
    const handleLanguageSelect = (language: string) => {
        setIsFirstLogin(false)
        console.log(language)
    };

    if (isFirstLogin) {
        return <LanguageSelection onLanguageSelect={handleLanguageSelect} />;
    }

    return (
        <>
            <ChatPage selectedLanguage={"user.selectedLanguage"} />
        </>
    );
};

export default Home;