import asyncio
import functools
from typing import Any, Awaitable, Callable, ParamSpec

import asyncpg
import click

P = ParamSpec('P')

loop = asyncio.new_event_loop()


def coro(f: Callable[P, Awaitable[Any]]) -> Callable[P, Callable[P, Any]]:
    @functools.wraps(f)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> Any:
        return loop.run_until_complete(f(*args, **kwargs))

    return wrapper


@click.group()
@click.pass_context
@coro
async def cli(ctx: click.Context) -> None:
    pool = await asyncpg.create_pool(
        user='postgres',
        password='postgres',
        database='university_test',
        host='localhost',
    )

    ctx.ensure_object(dict)
    ctx.obj['pool'] = pool


@cli.command()
@click.pass_context
@coro
async def library_users(ctx: click.Context) -> None:
    pool: asyncpg.Pool = ctx.obj['pool']
    rows = await pool.fetch(
        """
        SELECT 
            user_name
            , sum(books_cnt) AS books_cnt
        FROM users_book()
        GROUP BY user_name
        ORDER BY books_cnt DESC, user_name
        """
    )
    print('{:>15} {:>10}'.format('user_name', 'books_cnt'))
    print(
        '\n'.join(['{:>15} {:>10}'.format(row['user_name'], row['books_cnt']) for row in rows])
    )


@cli.command()
@click.option('--users', multiple=True)
@click.pass_context
@coro
async def users_best_genre(ctx: click.Context, users: list[str]) -> None:
    pool: asyncpg.Pool = ctx.obj['pool']

    rows = await pool.fetch(
        """
        SELECT
            user_name
            , genre_name
            , books_cnt
        FROM users_genres
        WHERE
            (user_name, books_cnt) IN (
                SELECT user_name, max(books_cnt)
                FROM users_genres
                WHERE
                    array_length($1::varchar[], 1) IS NOT NULL
                    AND user_name = ANY($1::varchar[])
                    OR array_length($1::varchar[], 1) IS NULL
                GROUP BY user_name
            )
        """, users
    )

    print('{:>15} {:>15} {:>10}'.format('user_name', 'best_genre', 'books_cnt'))
    print(
        '\n'.join(['{:>15} {:>15} {:>10}'.format(row['user_name'], row['genre_name'], row['books_cnt']) for row in rows])
    )


if __name__ == "__main__":
    cli()
