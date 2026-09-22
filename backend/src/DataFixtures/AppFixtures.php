<?php
namespace App\DataFixtures;

use App\Entity\Category;
use App\Entity\City;
use App\Entity\Country;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;

final class AppFixtures extends Fixture
{
    public function load(ObjectManager $manager): void
    {
        $tm = new Country('TM', 'Turkmenistan');
        $ashgabat = new City($tm, 'Ashgabat');
        $manager->persist($tm);
        $manager->persist($ashgabat);

        $categories = [
            ['hair', ['tk' => 'Saç', 'ru' => 'Волосы', 'en' => 'Hair']],
            ['nails', ['tk' => 'Dyrnak', 'ru' => 'Ногти', 'en' => 'Nails']],
            ['makeup', ['tk' => 'Makiýaž', 'ru' => 'Макияж', 'en' => 'Makeup']],
            ['brows-lashes', ['tk' => 'Gaşlar we kirpikler', 'ru' => 'Брови и ресницы', 'en' => 'Brows & Lashes']],
            ['skincare-cosmetology', ['tk' => 'Derä idegi / Kosmetologiýa', 'ru' => 'Уход за кожей / Косметология', 'en' => 'Skincare / Cosmetology']],
            ['bridal-beauty', ['tk' => 'Gelin gözelligi', 'ru' => 'Свадебная красота', 'en' => 'Bridal Beauty']],
        ];
        foreach ($categories as $i => [$slug, $names]) {
            $category = (new Category($slug, $names))->setSortOrder($i + 1);
            $manager->persist($category);
        }
        $manager->flush();
    }
}
